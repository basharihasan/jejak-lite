# frozen_string_literal: true

require "csv"

# Impor nilai massal ke satu AssessmentEvent dengan PEMETAAN KOLOM (Flexible
# Column Mapper ala jejak.pro). Dua bentuk berkas didukung:
#
#   1. Nilai total saja — kolom email + skor (+ nilai maks / percobaan).
#   2. **Nilai per dimensi** — satu kolom per mata uji CBT atau per station
#      OSCE. Nilai total dihitung dari dimensi (rata-rata terbobot × nilai
#      maksimum event) kecuali kolom skor total ikut dipetakan.
#
# Aturan percobaan:
#   - event tanpa percobaan berulang → selalu percobaan 1 (nilai lama ditimpa);
#   - event berpercobaan-ulang → pakai kolom percobaan bila dipetakan, kalau
#     tidak, percobaan berikutnya untuk mahasiswa itu.
class AssessmentScoreImporter
  Result = Struct.new(:created, :updated, :unmatched, :errors, :dimension_scores, :skipped, keyword_init: true) do
    def imported = created + updated
  end

  def self.parse_headers(csv_text)
    sep = detect_separator(csv_text)
    table = CSV.parse(csv_text, headers: true, col_sep: sep)
    [ table.headers.compact.map(&:to_s), table.first(3).map(&:fields) ]
  rescue CSV::MalformedCSVError
    [ [], [] ]
  end

  def self.detect_separator(text)
    first = text.to_s.lines.first.to_s
    first.count(";") > first.count(",") ? ";" : ","
  end

  # mapping: { "email" => kolom, "score" => kolom|nil, "max_score" => kolom|nil, "attempt" => kolom|nil,
  #            "date" => kolom|nil }  — tanggal kosong = tanggal ujian event
  # dimension_mapping: { dimension_id => kolom }
  def initialize(event:, csv_text:, mapping:, dimension_mapping: {})
    @event = event
    @csv_text = csv_text.to_s.force_encoding("UTF-8").delete_prefix("﻿")
    @mapping = mapping.to_h.transform_keys(&:to_s).transform_values { |v| v.to_s.presence }
    @dimension_mapping = dimension_mapping.to_h.transform_keys(&:to_i).transform_values { |v| v.to_s.presence }.compact
    @dimensions = event.assessment_dimensions.index_by(&:id)
  end

  def call
    result = Result.new(created: 0, updated: 0, unmatched: [], errors: [], dimension_scores: 0, skipped: 0)
    if @mapping["email"].blank?
      result.errors << "Kolom email wajib dipetakan."
      return result
    end
    if @mapping["score"].blank? && @dimension_mapping.empty?
      result.errors << "Petakan kolom skor total, atau minimal satu kolom dimensi (mata uji / station)."
      return result
    end

    sep = self.class.detect_separator(@csv_text)
    CSV.parse(@csv_text, headers: true, col_sep: sep).each_with_index do |row, idx|
      line = idx + 2
      email = row[@mapping["email"]].to_s.strip.downcase
      next if email.blank? && row.fields.compact.empty?

      # Baris tanpa nilai sama sekali (mis. dari templat berisi daftar
      # mahasiswa yang belum diisi) dilewati — dulu tercatat sebagai skor 0
      # dan menimpa nilai yang sudah ada.
      unless row_has_value?(row)
        result.skipped += 1
        next
      end

      student = User.find_by(email: email)
      if student.nil?
        result.unmatched << email.presence || "(baris #{line} tanpa email)"
        next
      end

      attempt = resolve_attempt(row, student)
      instance = AssessmentInstance.find_or_initialize_by(assessment_event: @event, student: student, attempt_number: attempt)
      new_record = instance.new_record?
      instance.max_score = numeric(row, @mapping["max_score"]) || @event.max_score
      instance.status = "scored"
      instance.source = "import"
      scored_on = parse_date(row, @mapping["date"])
      if scored_on == :invalid
        result.errors << "Baris #{line} (#{email}): tanggal \"#{row[@mapping["date"]]}\" tidak dikenali — pakai format 2026-09-17 atau 17/09/2026."
        next
      end
      instance.scored_at = scored_on&.in_time_zone || @event.exam_date&.in_time_zone || Time.current
      instance.score = numeric(row, @mapping["score"]) || 0

      begin
        AssessmentInstance.transaction do
          instance.save!
          written = write_dimension_scores(instance, row, line, result)
          # Nilai total dihitung dari dimensi kecuali kolom total dipetakan.
          instance.recalculate_from_dimensions! if written.positive? && @mapping["score"].blank?
        end
        result.public_send(new_record ? :created= : :updated=, result.public_send(new_record ? :created : :updated) + 1)
      rescue ActiveRecord::RecordInvalid => e
        result.errors << "Baris #{line} (#{email}): #{e.record.errors.full_messages.to_sentence}"
      end
    end
    result
  rescue CSV::MalformedCSVError => e
    Result.new(created: 0, updated: 0, unmatched: [], errors: [ "CSV tidak dapat dibaca: #{e.message}" ], dimension_scores: 0, skipped: 0)
  end

  private

  def row_has_value?(row)
    ([ @mapping["score"] ] + @dimension_mapping.values).compact.any? { |column| row[column].to_s.strip.present? }
  end

  def write_dimension_scores(instance, row, line, result)
    written = 0
    @dimension_mapping.each do |dimension_id, column|
      dimension = @dimensions[dimension_id]
      next if dimension.nil?

      value = numeric(row, column)
      next if value.nil?

      record = AssessmentDimensionScore.find_or_initialize_by(assessment_instance: instance, assessment_dimension: dimension)
      record.score = value
      if record.save
        written += 1
        result.dimension_scores += 1
      else
        result.errors << "Baris #{line}, #{dimension.label}: #{record.errors.full_messages.to_sentence}"
      end
    end
    written
  end

  def numeric(row, column)
    return nil if column.blank?

    raw = row[column].to_s.strip.tr(",", ".")
    return nil if raw.blank?
    return nil unless raw.match?(/\A\d+(\.\d+)?\z/)

    raw.to_f
  end

  # Terima ISO (2026-09-17) dan format Indonesia/Excel (17/09/2026,
  # 17-09-2026). Kosong -> nil; tak terbaca -> :invalid.
  def parse_date(row, column)
    return nil if column.blank?

    raw = row[column].to_s.strip
    return nil if raw.blank?

    case raw
    when /\A(\d\d\d\d)-(\d\d?)-(\d\d?)\z/ then Date.new($1.to_i, $2.to_i, $3.to_i)
    when %r{\A(\d\d?)[/.-](\d\d?)[/.-](\d\d\d\d)\z} then Date.new($3.to_i, $2.to_i, $1.to_i)
    else :invalid
    end
  rescue Date::Error
    :invalid
  end

  def resolve_attempt(row, student)
    return 1 unless @event.allow_multiple_attempts?

    if @mapping["attempt"].present?
      n = row[@mapping["attempt"]].to_i
      return n if n.positive?
    end
    AssessmentInstance.next_attempt_number(@event, student)
  end
end
