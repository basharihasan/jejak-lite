# frozen_string_literal: true

class AssessmentFormField < ApplicationRecord
  FIELD_TYPES = {
    "rating" => "Skala Penilaian (1–5)",
    "yes_no" => "Ya/Tidak",
    "text" => "Teks Singkat",
    "textarea" => "Teks Panjang"
  }.freeze

  belongs_to :assessment_form_template
  has_many :assessment_form_answers, dependent: :destroy

  validates :label, presence: true
  validates :field_type, inclusion: { in: FIELD_TYPES.keys }

  before_create :assign_position

  def field_type_label
    FIELD_TYPES.fetch(field_type, field_type)
  end

  private

  def assign_position
    self.position = (assessment_form_template.assessment_form_fields.maximum(:position) || 0) + 1
  end
end
