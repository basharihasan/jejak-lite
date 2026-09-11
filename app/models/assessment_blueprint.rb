# frozen_string_literal: true

# Rencana cakupan asesmen (Blueprinting) — berdiri sendiri tanpa asosiasi
# apa pun, meniru AssessmentBlueprint JEJAK. Bukan data hasil, tapi
# rencana: seberapa besar bobot tiap ranah kompetensi dalam satu asesmen.
class AssessmentBlueprint < ApplicationRecord
  validates :name, presence: true
  validate :competency_mapping_sums_to_100, if: -> { competency_mapping.present? }

  def total_weight
    competency_mapping.values.sum(&:to_f)
  end

  private

  def competency_mapping_sums_to_100
    return if competency_mapping.blank?

    total = total_weight
    return if (total - 100).abs < 0.01

    errors.add(:competency_mapping, "totalnya harus 100% (saat ini #{total.round(1)}%)")
  end
end
