# frozen_string_literal: true

# Jurnal reflektif tersendiri — beda dari field `reflection` ringkas di
# ActivityLog/ClinicalCase, ini untuk tulisan reflektif yang lebih bebas,
# bisa berdiri sendiri atau ditautkan ke kegiatan/kasus tertentu.
class ReflectionEntry < ApplicationRecord
  belongs_to :user
  belongs_to :activity_log, optional: true
  belongs_to :clinical_case, optional: true

  validates :entry_date, :content, presence: true

  scope :recent, -> { order(entry_date: :desc, created_at: :desc) }
end
