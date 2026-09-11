# frozen_string_literal: true

class ExaminerScore < ApplicationRecord
  belongs_to :final_project
  belongs_to :examiner, class_name: "User"

  validates :session_date, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  after_create_commit :notify_student

  private

  def notify_student
    Notification.notify!(
      recipient: final_project.student, sender: examiner, notifiable: final_project,
      title: "Skor ujian tugas akhir baru",
      message: "#{examiner.full_name} memberi skor #{score} untuk \"#{final_project.title}\"."
    )
  end
end
