# frozen_string_literal: true

# Nilai satu mahasiswa pada satu dimensi (mata uji CBT / station OSCE).
class AssessmentDimensionScore < ApplicationRecord
  belongs_to :assessment_instance
  belongs_to :assessment_dimension

  validates :score, numericality: { greater_than_or_equal_to: 0 }
  validates :assessment_dimension_id, uniqueness: { scope: :assessment_instance_id }
  validate :score_within_dimension_scale

  delegate :competency_item, :weight, :max_score, :label, to: :assessment_dimension

  def percentage
    assessment_dimension.percentage_of(score)
  end

  private

  def score_within_dimension_scale
    return if score.blank?
    return if score <= assessment_dimension.max_score

    errors.add(:score, "melebihi nilai maksimum dimensi #{assessment_dimension.label} (#{assessment_dimension.max_score})")
  end
end
