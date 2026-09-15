# frozen_string_literal: true

class AssessmentFormField < ApplicationRecord
  FIELD_TYPES = {
    "rating" => "Skala Penilaian (1–5)",
    "score" => "Skor Angka (0–maks)",
    "rubric_level" => "Rubrik Berjenjang (deskriptor per tingkat)",
    "select" => "Pilihan Ganda",
    "yes_no" => "Ya/Tidak",
    "text" => "Teks Singkat",
    "textarea" => "Teks Panjang"
  }.freeze

  # Tipe yang ikut membentuk nilai rubrik. Ya/Tidak, pilihan ganda, dan teks
  # tetap direkam tetapi tidak dihitung — jawaban naratif bukan angka.
  SCORABLE_TYPES = %w[rating score rubric_level].freeze
  # Tipe yang memerlukan daftar pilihan pada kolom `options`.
  OPTION_TYPES = %w[rubric_level select].freeze

  # Contoh jenjang yang dipakai saat admin memilih Rubrik Berjenjang dan
  # belum mengisi apa pun — empat tingkat ala rubrik klinis.
  DEFAULT_RUBRIC_LEVELS = [
    { "label" => "Belum kompeten", "description" => "Belum mampu melakukan tanpa arahan penuh.", "score" => 1 },
    { "label" => "Cukup", "description" => "Mampu dengan bimbingan pada bagian penting.", "score" => 2 },
    { "label" => "Baik", "description" => "Mampu mandiri dengan supervisi tidak langsung.", "score" => 3 },
    { "label" => "Sangat baik", "description" => "Mandiri, runtut, dan mampu menjelaskan alasannya.", "score" => 4 }
  ].freeze

  belongs_to :assessment_form_template
  belongs_to :competency_item, optional: true
  has_many :assessment_form_answers, dependent: :destroy

  validates :label, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES.keys }
  validates :max_score, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :field_type_locked_once_answered
  validate :options_present_for_option_types

  before_validation :normalize_options
  before_validation :normalize_scale
  before_create :assign_position

  scope :ordered, -> { order(:position, :id) }
  scope :scorable, -> { where(field_type: SCORABLE_TYPES) }
  scope :mapped, -> { where.not(competency_item_id: nil) }

  def field_type_label = FIELD_TYPES.fetch(field_type, field_type)

  def scorable?
    SCORABLE_TYPES.include?(field_type)
  end

  def option_based?
    OPTION_TYPES.include?(field_type)
  end

  def mapped?
    competency_item_id.present?
  end

  def answered?
    assessment_form_answers.exists?
  end

  def min_value
    field_type == "rating" ? 1 : 0
  end

  # [{ label:, description:, score: }] — untuk select, skor diabaikan.
  def option_rows
    Array(options).map { |row| row.to_h.symbolize_keys }
  end

  def option_values
    option_rows.map { |row| row[:label].to_s }
  end

  def option_for(value)
    option_rows.find { |row| row[:label].to_s == value.to_s }
  end

  # Nilai 0–1 dari satu jawaban; nil bila kosong atau bukan tipe skor.
  def normalized(value)
    return nil unless scorable?
    return normalized_rubric(value) if field_type == "rubric_level"

    number = value.to_s.tr(",", ".")
    return nil if number.blank? || !number.match?(/\A\d+(\.\d+)?\z/)

    [ number.to_f / max_score, 1.0 ].min
  end

  # ── Urutan pertanyaan ──
  def move_up!
    swap_with(siblings.where(position: ...position).order(position: :desc).first)
  end

  def move_down!
    swap_with(siblings.where("position > ?", position).order(:position).first)
  end

  # Teks "label | deskripsi | skor" per baris — bentuk yang disunting admin.
  def options_text
    option_rows.map do |row|
      if field_type == "select"
        row[:label]
      else
        [ row[:label], row[:description].presence, row[:score] ].compact.join(" | ")
      end
    end.join("\n")
  end

  def options_text=(text)
    @options_text = text
  end

  attr_reader :options_text_input

  private

  def siblings
    assessment_form_template.assessment_form_fields.ordered.where.not(id: id)
  end

  def swap_with(other)
    return false if other.nil?

    self.class.transaction do
      mine = position
      update_column(:position, other.position)
      other.update_column(:position, mine)
    end
    true
  end

  def normalized_rubric(value)
    row = option_for(value)
    return nil if row.nil?

    score = row[:score].to_f
    return nil if max_score.to_f.zero?

    [ score / max_score, 1.0 ].min
  end

  # Baris "label | deskripsi | skor"; skor boleh kosong (diisi urutan jenjang).
  def normalize_options
    unless option_based?
      self.options = []
      return
    end

    if @options_text.present?
      rows = @options_text.to_s.split("\n").filter_map do |line|
        parts = line.split("|").map(&:strip)
        next if parts.first.blank?

        { "label" => parts[0], "description" => parts[1].to_s, "score" => parts[2] }
      end
      rows.each_with_index { |row, index| row["score"] = (row["score"].presence || index + 1).to_i }
      self.options = rows
    elsif options.blank? && field_type == "rubric_level"
      self.options = DEFAULT_RUBRIC_LEVELS.map(&:dup)
    end

    # Skala rubrik mengikuti skor jenjang tertinggi supaya persentasenya benar.
    self.max_score = option_rows.map { |row| row[:score].to_i }.max if field_type == "rubric_level" && option_rows.any?
  end

  # Skala "rating" selalu 1–5 (itu namanya); tipe non-skor tidak memakai
  # skala/bobot, jadi nilainya dikembalikan ke bawaan agar tidak menyesatkan.
  def normalize_scale
    self.max_score = 5 if field_type == "rating"
    return if scorable?

    self.max_score = 5
    self.weight = 1
  end

  def assign_position
    self.position = (assessment_form_template.assessment_form_fields.maximum(:position) || 0) + 1
  end

  def options_present_for_option_types
    return unless option_based?
    return if option_rows.any? { |row| row[:label].present? }

    errors.add(:options_text, "harus diisi — tuliskan satu pilihan/jenjang per baris")
  end

  # Mengubah tipe setelah ada jawaban membuat jawaban lama tak bermakna
  # (mis. "4" pada skala 1–5 berubah arti saat tipe menjadi teks) dan
  # diam-diam menggeser nilai rubrik yang sudah keluar.
  def field_type_locked_once_answered
    return unless persisted? && field_type_changed? && answered?

    errors.add(:field_type, "tidak dapat diubah karena pertanyaan ini sudah punya jawaban — buat pertanyaan baru sebagai gantinya")
  end
end
