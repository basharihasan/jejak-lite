# frozen_string_literal: true

class AssessmentFormAnswer < ApplicationRecord
  belongs_to :assessment_form_submission
  belongs_to :assessment_form_field

  validate :required_field_answered

  private

  def required_field_answered
    return unless assessment_form_field&.required?
    return if value.present?

    errors.add(:value, "#{assessment_form_field.label} wajib diisi")
  end
end
