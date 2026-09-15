# frozen_string_literal: true

class MiniCexEvaluation < ApplicationRecord
  include DimensionScorable
  include ClinicalContextOptions

  # 6 dimensi numerik (1-9) meniru rubrik Mini-CEX JEJAK asli. Penilaian
  # keseluruhan TIDAK jadi dimensi numerik ke-7 lagi — dipindah ke
  # `global_rating`, field kualitatif 4-pilihan terpisah (lihat
  # GLOBAL_RATING_OPTIONS), karena itu memang bagaimana Mini-CEX standar
  # menilainya (bukan skala 1-9).
  DIMENSIONS = {
    "anamnesis" => "Keterampilan Anamnesis",
    "pemeriksaan_fisik" => "Keterampilan Pemeriksaan Fisik",
    "clinical_judgment" => "Clinical Judgment",
    "komunikasi" => "Keterampilan Komunikasi",
    "profesionalisme" => "Profesionalisme",
    "organisasi" => "Organisasi & Efisiensi"
  }.freeze
  REQUIRED_DIMENSIONS = %w[komunikasi profesionalisme].freeze

  GLOBAL_RATING_OPTIONS = {
    "needs_development" => "Perlu Banyak Perbaikan",
    "borderline" => "Batas Bawah",
    "performed" => "Sesuai Harapan",
    "exceptional" => "Melebihi Harapan"
  }.freeze

  belongs_to :student, class_name: "User"
  belongs_to :evaluator, class_name: "User"
  belongs_to :clinical_rotation

  validates :case_description, presence: true
  validates :global_rating, inclusion: { in: GLOBAL_RATING_OPTIONS.keys }, unless: :requested?

  scope :recent, -> { order(evaluated_at: :desc) }

  def global_rating_label
    GLOBAL_RATING_OPTIONS.fetch(global_rating, global_rating)
  end

  private

  def notify_student
    Notification.notify!(
      recipient: student, sender: evaluator, notifiable: self,
      title: "Mini-CEX baru: #{case_description}",
      message: "Skor rata-rata: #{average_score || "-"}/9"
    )
  end
end
