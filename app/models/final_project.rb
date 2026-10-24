# frozen_string_literal: true

class FinalProject < ApplicationRecord
  STATUSES = { "proposal" => "Proposal", "ongoing" => "Berjalan", "completed" => "Selesai" }.freeze

  belongs_to :student, class_name: "User"
  belongs_to :supervisor, class_name: "User", optional: true

  has_many :final_project_milestones, -> { order(:target_date) }, dependent: :destroy, inverse_of: :final_project
  has_many :examiner_scores, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES.keys }
  # Pembimbing mendapat hak sunting proyek (FinalProjectPolicy), jadi hanya
  # akun dosen — sama dengan pilihan di formulir — dan bukan diri sendiri.
  validate :supervisor_is_eligible, if: :will_save_change_to_supervisor_id?

  def status_label
    STATUSES.fetch(status, status)
  end

  def average_examiner_score
    scores = examiner_scores.pluck(:score).compact
    return nil if scores.empty?

    (scores.sum / scores.size).round(2)
  end

  def milestones_completed_count
    final_project_milestones.where.not(completed_at: nil).count
  end

  private

  def supervisor_is_eligible
    return if supervisor_id.nil?

    if supervisor_id == student_id
      errors.add(:supervisor, "tidak boleh diri sendiri")
    elsif !UserRole.joins(:role).exists?(user_id: supervisor_id, roles: { code: "dosen" })
      errors.add(:supervisor, "harus dosen")
    end
  end
end
