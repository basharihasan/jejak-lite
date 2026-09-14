# frozen_string_literal: true

# Jadwal DOPS & Mini-CEX — rencana penilaian di tempat kerja per mahasiswa &
# penilai. Bukan evaluasinya sendiri: DOPS/Mini-CEX tetap dicatat lewat form
# masing-masing; jadwal ini yang ditandai "selesai".
class EvaluationSchedule < ApplicationRecord
  KINDS = { "dops" => "DOPS", "mini_cex" => "Mini-CEX" }.freeze
  STATUSES = { "planned" => "Terjadwal", "done" => "Selesai", "cancelled" => "Dibatalkan" }.freeze

  belongs_to :student, class_name: "User"
  belongs_to :evaluator, class_name: "User", optional: true
  belongs_to :clinical_rotation, optional: true

  validates :kind, inclusion: { in: KINDS.keys }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :scheduled_at, presence: true

  scope :upcoming, -> { where(status: "planned").where("scheduled_at >= ?", Time.current.beginning_of_day).order(:scheduled_at) }
  scope :for_user, ->(user) { where("student_id = :id OR evaluator_id = :id", id: user.id) }
  scope :ordered, -> { order(scheduled_at: :desc) }

  def kind_label = KINDS.fetch(kind, kind)
  def status_label = STATUSES.fetch(status, status)
end
