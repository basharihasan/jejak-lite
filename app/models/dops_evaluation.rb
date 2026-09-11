# frozen_string_literal: true

class DopsEvaluation < ApplicationRecord
  include DimensionScorable
  include ClinicalContextOptions

  # 10 dimensi meniru rubrik DOPS JEJAK asli (bukan versi ringkas 6 dimensi
  # sebelumnya). Komunikasi, profesionalisme, dan penilaian global SELALU
  # wajib diisi (tidak boleh N/A) — dimensi teknis lainnya boleh N/A kalau
  # memang tidak relevan untuk prosedur tertentu.
  DIMENSIONS = {
    "persetujuan_tindakan" => "Persetujuan Tindakan (Informed Consent)",
    "persiapan" => "Persiapan Tindakan",
    "analgesia_sedasi" => "Analgesia/Sedasi",
    "kemampuan_teknis" => "Kemampuan Teknis",
    "asepsis" => "Asepsis & Keamanan Pasien",
    "meminta_bantuan" => "Meminta Bantuan Saat Diperlukan",
    "pasca_tindakan" => "Evaluasi Pasca Tindakan",
    "komunikasi" => "Komunikasi dengan Pasien",
    "profesionalisme" => "Profesionalisme",
    "penilaian_global" => "Penilaian Global"
  }.freeze
  REQUIRED_DIMENSIONS = %w[komunikasi profesionalisme penilaian_global].freeze

  # Datalist autocomplete ringan di form — bukan daftar tertutup (evaluator
  # tetap bisa mengetik nama lain), cuma mempercepat entri untuk prosedur umum.
  COMMON_PROCEDURES = [
    "Pemasangan Infus", "Pemasangan Kateter Urin", "Jahit Luka", "Pungsi Vena",
    "Insisi Abses", "Pemasangan NGT", "Resusitasi Jantung Paru", "Injeksi Intramuskular",
    "Pemasangan Bidai", "Pemeriksaan Rectal Toucher"
  ].freeze

  belongs_to :student, class_name: "User"
  belongs_to :evaluator, class_name: "User"
  belongs_to :clinical_rotation

  validates :procedure_name, presence: true

  scope :recent, -> { order(evaluated_at: :desc) }

  private

  def notify_student
    Notification.notify!(
      recipient: student, sender: evaluator, notifiable: self,
      title: "DOPS baru: #{procedure_name}",
      message: "Skor rata-rata: #{average_score || "-"}/9"
    )
  end
end
