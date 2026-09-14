# frozen_string_literal: true

# Master Diagnosis — nama penyakit SKDI + kode ICD-10 + level kompetensi.
# Mengisi datalist wizard kasus klinis; ClinicalCase#sync_diagnosis_definition
# menyalin icd10_code & skdi_level saat teks diagnosis cocok.
class DiagnosisDefinition < ApplicationRecord
  SKDI_LEVELS = %w[1 2 3A 3B 4A].freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :skdi_level, inclusion: { in: SKDI_LEVELS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :search, ->(q) {
    q = q.to_s.strip
    next all if q.blank?

    like = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :q OR icd10_code ILIKE :q OR system_group ILIKE :q", q: like)
  }

  # Cocokkan teks bebas diagnosis: persis nama (tanpa peduli huruf), atau
  # diawali "KODE — " / "KODE - " seperti yang dihasilkan datalist.
  def self.match(text)
    t = text.to_s.strip
    return nil if t.blank?

    candidate = t.sub(/\A[A-Z][0-9]{2}(\.[0-9A-Z]{1,2})?\s*[—–-]\s*/, "")
    active.find_by("LOWER(name) = ?", candidate.downcase) || active.find_by("LOWER(name) = ?", t.downcase)
  end

  def label
    [ icd10_code.presence, name ].compact.join(" — ")
  end
end
