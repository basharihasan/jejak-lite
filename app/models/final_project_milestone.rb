# frozen_string_literal: true

class FinalProjectMilestone < ApplicationRecord
  belongs_to :final_project

  validates :title, :target_date, presence: true

  scope :pending, -> { where(completed_at: nil) }

  def completed?
    completed_at.present?
  end

  def overdue?
    !completed? && target_date < Date.current
  end

  def toggle_completed!
    update!(completed_at: completed? ? nil : Time.current)
  end
end
