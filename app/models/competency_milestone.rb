# frozen_string_literal: true

# Target skor per domain kompetensi untuk SATU periode akademik — versi
# ringan dari CompetencyGrowthTarget JEJAK asli (yang punya 3 tingkat
# target + kurva pertumbuhan lintas-kohort). jejak-lite sengaja cuma satu
# target per domain per periode, tanpa mesin kohort/tren (lihat catatan
# arsitektur di IMPLEMENTATION_PLAN.md § Fase 20).
class CompetencyMilestone < ApplicationRecord
  belongs_to :competency_item
  belongs_to :academic_period

  validates :expected_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9 }
  validates :academic_period_id, uniqueness: { scope: :competency_item_id }
end
