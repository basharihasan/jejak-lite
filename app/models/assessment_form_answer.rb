# frozen_string_literal: true

class AssessmentFormAnswer < ApplicationRecord
  belongs_to :assessment_form_submission
  belongs_to :assessment_form_field

  validate :required_field_answered
  validate :value_within_scale
  validate :value_within_options

  delegate :scorable?, to: :assessment_form_field

  def numeric_value
    assessment_form_field.normalized(value)
  end

  private

  def required_field_answered
    return unless assessment_form_field&.required?
    return if value.present?

    errors.add(:base, "#{assessment_form_field.label} wajib diisi")
  end

  # Jawaban di luar daftar pilihan/jenjang = rubrik salah hitung tanpa ada
  # yang tahu, jadi ditolak, bukan disimpan apa adanya.
  def value_within_options
    return unless assessment_form_field&.option_based?
    return if value.blank?
    return if assessment_form_field.option_values.include?(value.to_s)

    errors.add(:base, "#{assessment_form_field.label}: pilihan \"#{value}\" tidak ada dalam daftar")
  end

  # Nilai skor di luar skala berarti rubrik salah hitung tanpa ada yang tahu.
  def value_within_scale
    return unless assessment_form_field&.scorable?
    return if assessment_form_field.option_based?
    return if value.blank?

    number = value.to_s.tr(",", ".")
    unless number.match?(/\A\d+(\.\d+)?\z/)
      errors.add(:base, "#{assessment_form_field.label} harus berupa angka")
      return
    end

    min = assessment_form_field.min_value
    max = assessment_form_field.max_score
    return if number.to_f.between?(min, max)

    errors.add(:base, "#{assessment_form_field.label} harus bernilai #{min}–#{max}")
  end
end
