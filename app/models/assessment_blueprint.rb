# frozen_string_literal: true

# Rencana cakupan asesmen (Blueprinting) — berdiri sendiri tanpa asosiasi
# apa pun, meniru AssessmentBlueprint JEJAK. Bukan data hasil, tapi
# rencana: seberapa besar bobot tiap ranah kompetensi dalam satu asesmen.
class AssessmentBlueprint < ApplicationRecord
  has_many :assessment_blueprint_mappings, dependent: :destroy
  has_many :competency_items, through: :assessment_blueprint_mappings

  validates :name, presence: true
  validate :mapping_weights_sum_to_100, if: -> { assessment_blueprint_mappings.any? }

  def total_weight
    assessment_blueprint_mappings.sum { |m| m.weight.to_f }
  end

  # {CompetencyItem => bobot} — dipakai halaman show untuk radar chart,
  # sudah dalam bentuk siap-pakai (bukan JSONB label bebas lagi).
  def weight_by_competency_item
    assessment_blueprint_mappings.includes(:competency_item).index_by(&:competency_item).transform_values { |m| m.weight.to_f }
  end

  private

  def mapping_weights_sum_to_100
    total = total_weight
    return if (total - 100).abs < 0.01

    errors.add(:base, "Total bobot peta kompetensi harus 100% (saat ini #{total.round(1)}%)")
  end
end
