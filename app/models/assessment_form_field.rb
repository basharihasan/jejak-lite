# frozen_string_literal: true

class AssessmentFormField < ApplicationRecord
  FIELD_TYPES = {
    "rating" => "Skala Penilaian (1–5)",
    "score" => "Skor Angka (0–maks)",
    "yes_no" => "Ya/Tidak",
    "text" => "Teks Singkat",
    "textarea" => "Teks Panjang"
  }.freeze

  # Tipe yang ikut membentuk nilai rubrik. Ya/Tidak & teks tetap direkam
  # tetapi tidak dihitung — jawaban naratif bukan angka.
  SCORABLE_TYPES = %w[rating score].freeze

  belongs_to :assessment_form_template
  has_many :assessment_form_answers, dependent: :destroy

  validates :label, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES.keys }
  validates :max_score, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :field_type_locked_once_answered

  before_validation :normalize_scale
  before_create :assign_position

  scope :ordered, -> { order(:position, :id) }
  scope :scorable, -> { where(field_type: SCORABLE_TYPES) }

  def field_type_label = FIELD_TYPES.fetch(field_type, field_type)

  def scorable?
    SCORABLE_TYPES.include?(field_type)
  end

  def answered?
    assessment_form_answers.exists?
  end

  def min_value
    field_type == "rating" ? 1 : 0
  end

  # Nilai 0–1 dari satu jawaban; nil bila kosong atau bukan tipe skor.
  def normalized(value)
    return nil unless scorable?

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

  # Mengubah tipe setelah ada jawaban membuat jawaban lama tak bermakna
  # (mis. "4" pada skala 1–5 berubah arti saat tipe menjadi teks) dan
  # diam-diam menggeser nilai rubrik yang sudah keluar.
  def field_type_locked_once_answered
    return unless persisted? && field_type_changed? && answered?

    errors.add(:field_type, "tidak dapat diubah karena pertanyaan ini sudah punya jawaban — buat pertanyaan baru sebagai gantinya")
  end
end
