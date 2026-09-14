# frozen_string_literal: true

# Tingkat entrustment EPA 1–5 (skala jejak.pro) per mahasiswa × ranah
# kompetensi. Setiap keputusan baru MENGGANTIKAN (supersede) yang lama —
# riwayat tetap tersimpan untuk audit. EPA = ranah tingkat atas kerangka
# kompetensi (CompetencyFramework#domains); jejak-lite sengaja tanpa
# katalog EPA terpisah.
class EntrustmentDecision < ApplicationRecord
  LEVELS = {
    1 => "Hanya mengamati, tidak boleh terlibat",
    2 => "Boleh terlibat dengan supervisi penuh",
    3 => "Bisa mandiri dengan supervisi tidak langsung",
    4 => "Mandiri penuh",
    5 => "Mampu mengajarkan dan mensupervisi junior"
  }.freeze

  # Pemetaan 6 level entrustment verifikasi kasus (ClinicalCase) → skala 1–5.
  CASE_LEVEL_MAP = {
    "diobservasi" => 1, "dibantu" => 2, "supervisi_langsung" => 2,
    "supervisi_tidak_langsung" => 3, "mandiri" => 4, "mengajari_junior" => 5
  }.freeze

  MIN_JUSTIFICATION = 10

  belongs_to :student, class_name: "User"
  belongs_to :competency_item
  belongs_to :decided_by, class_name: "User"
  belongs_to :clinical_case, optional: true
  belongs_to :superseded_by, class_name: "EntrustmentDecision", optional: true

  validates :level, inclusion: { in: LEVELS.keys }
  validates :justification, presence: true, length: { minimum: MIN_JUSTIFICATION, message: "minimal #{MIN_JUSTIFICATION} karakter" }

  scope :current, -> { where(superseded_at: nil) }
  scope :history, -> { order(created_at: :desc) }

  def level_label = LEVELS[level]

  # Membuat keputusan baru dan menandai keputusan lama (mahasiswa × ranah
  # yang sama) sebagai tergantikan — atomik.
  def self.decide!(student:, competency_item:, level:, justification:, decided_by:, clinical_case: nil)
    transaction do
      decision = create!(student: student, competency_item: competency_item, level: level,
                         justification: justification, decided_by: decided_by, clinical_case: clinical_case)
      current.where(student: student, competency_item: competency_item).where.not(id: decision.id)
             .update_all(superseded_by_id: decision.id, superseded_at: Time.current)
      decision
    end
  end

  # Peta EPA seorang mahasiswa: [ranah, keputusan terkini atau nil] untuk
  # semua ranah kerangka kompetensi.
  def self.map_for(student, framework)
    latest = current.where(student: student).includes(:decided_by).index_by(&:competency_item_id)
    framework.domains.map { |item| [ item, latest[item.id] ] }
  end
end
