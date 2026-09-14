# frozen_string_literal: true

# Master Keterampilan Klinis (SKDI) — mengisi datalist nama prosedur pada DOPS.
class SkillDefinition < ApplicationRecord
  SKDI_LEVELS = %w[1 2 3 4A].freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :skdi_level, inclusion: { in: SKDI_LEVELS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:category, :name) }
  scope :search, ->(q) {
    q = q.to_s.strip
    next all if q.blank?

    like = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :q OR category ILIKE :q", q: like)
  }
end
