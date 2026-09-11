# frozen_string_literal: true

class DopsEvaluation < ApplicationRecord
  include DimensionScorable

  DIMENSIONS = {
    "persiapan" => "Persiapan Tindakan",
    "teknik" => "Teknik Pelaksanaan",
    "asepsis" => "Asepsis & Keamanan Pasien",
    "komunikasi" => "Komunikasi dengan Pasien",
    "profesionalisme" => "Profesionalisme",
    "pasca_tindakan" => "Evaluasi Pasca Tindakan"
  }.freeze
  REQUIRED_DIMENSIONS = %w[komunikasi profesionalisme].freeze

  belongs_to :student, class_name: "User"
  belongs_to :evaluator, class_name: "User"
  belongs_to :clinical_rotation

  validates :procedure_name, presence: true

  scope :recent, -> { order(evaluated_at: :desc) }

  after_create_commit :notify_student

  private

  def notify_student
    Notification.notify!(
      recipient: student, sender: evaluator, notifiable: self,
      title: "DOPS baru: #{procedure_name}",
      message: "Skor rata-rata: #{average_score || "-"}/9"
    )
  end
end
