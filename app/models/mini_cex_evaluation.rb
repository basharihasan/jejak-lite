# frozen_string_literal: true

class MiniCexEvaluation < ApplicationRecord
  include DimensionScorable

  DIMENSIONS = {
    "anamnesis" => "Keterampilan Anamnesis",
    "pemeriksaan_fisik" => "Keterampilan Pemeriksaan Fisik",
    "profesionalisme" => "Profesionalisme",
    "clinical_judgment" => "Clinical Judgment",
    "konseling" => "Keterampilan Konseling",
    "organisasi" => "Organisasi & Efisiensi",
    "kompetensi_keseluruhan" => "Kompetensi Klinis Keseluruhan"
  }.freeze
  REQUIRED_DIMENSIONS = %w[profesionalisme].freeze

  belongs_to :student, class_name: "User"
  belongs_to :evaluator, class_name: "User"
  belongs_to :clinical_rotation

  validates :case_description, presence: true

  scope :recent, -> { order(evaluated_at: :desc) }

  after_create_commit :notify_student

  private

  def notify_student
    Notification.notify!(
      recipient: student, sender: evaluator, notifiable: self,
      title: "Mini-CEX baru: #{case_description}",
      message: "Skor rata-rata: #{average_score || "-"}/9"
    )
  end
end
