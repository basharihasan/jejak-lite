# frozen_string_literal: true

require "csv"

# Impor nilai massal ke satu AssessmentEvent dengan PEMETAAN KOLOM (Flexible
# Column Mapper ala jejak.pro): admin memilih kolom mana yang berisi email
# mahasiswa, skor, nilai maksimum (opsional), dan nomor percobaan (opsional).
#
# Aturan percobaan:
#   - event tanpa percobaan berulang → selalu percobaan 1 (nilai lama ditimpa);
#   - event berpercobaan-ulang → pakai kolom percobaan bila dipetakan, kalau
#     tidak, percobaan berikutnya untuk mahasiswa itu.
class AssessmentScoreImporter
  Result = Struct.new(:created, :updated, :unmatched, :errors, keyword_init: true) do
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

  # mapping: { "email" => "kolom", "score" => "kolom", "max_score" => "kolom"|nil, "attempt" => "kolom"|nil }
  def initialize(event:, csv_text:, mapping:)
    @event = event
    @csv_text = csv_text.to_s.force_encoding("UTF-8").delete_prefix("﻿")
    @mapping = mapping.to_h.transform_keys(&:to_s).transform_values { |v| v.to_s.presence }
  end

  def call
    result = Result.new(created: 0, updated: 0, unmatched: [], errors: [])
    return result.tap { |r| r.errors << "Kolom email dan skor wajib dipetakan." } if @mapping["email"].blank? || @mapping["score"].blank?

    sep = self.class.detect_separator(@csv_text)
    CSV.parse(@csv_text, headers: true, col_sep: sep).each_with_index do |row, idx|
      line = idx + 2
      email = row[@mapping["email"]].to_s.strip.downcase
      next if email.blank? && row.fields.compact.empty?

      student = User.find_by(email: email)
      if student.nil?
        result.unmatched << email.presence || "(baris #{line} tanpa email)"
        next
      end

      score = row[@mapping["score"]].to_s.strip.tr(",", ".")
      max_score = @mapping["max_score"] ? row[@mapping["max_score"]].to_s.strip.tr(",", ".").presence : nil
      attempt = resolve_attempt(row, student)

      instance = AssessmentInstance.find_or_initialize_by(assessment_event: @event, student: student, attempt_number: attempt)
      new_record = instance.new_record?
      instance.assign_attributes(score: score, max_score: max_score || @event.max_score, status: "scored",
                                 source: "import", scored_at: @event.exam_date&.to_time || Time.current)
      if instance.save
        result.public_send(new_record ? :created= : :updated=, result.public_send(new_record ? :created : :updated) + 1)
      else
        result.errors << "Baris #{line} (#{email}): #{instance.errors.full_messages.to_sentence}"
      end
    end
    result
  rescue CSV::MalformedCSVError => e
    Result.new(created: 0, updated: 0, unmatched: [], errors: [ "CSV tidak dapat dibaca: #{e.message}" ])
  end

  private

  def resolve_attempt(row, student)
    return 1 unless @event.allow_multiple_attempts?

    if @mapping["attempt"].present?
      n = row[@mapping["attempt"]].to_i
      return n if n.positive?
    end
    AssessmentInstance.next_attempt_number(@event, student)
  end
end
