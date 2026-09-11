# frozen_string_literal: true

# Menggantikan competency_mapping JSONB bebas teks — meniru AssessmentDimensionMapping
# JEJAK asli (relasi FK ke kompetensi sungguhan, bukan label bebas yang bisa typo).
class AssessmentBlueprintMapping < ApplicationRecord
  belongs_to :assessment_blueprint
  belongs_to :competency_item

  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :competency_item_id, uniqueness: { scope: :assessment_blueprint_id }
end
