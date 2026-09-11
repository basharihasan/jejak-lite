# frozen_string_literal: true

class ExamScore < ApplicationRecord
  belongs_to :exam_import
  belongs_to :student, class_name: "User"

  validates :score, :max_score, :exam_date, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0 }

  delegate :kind, :kind_label, to: :exam_import

  scope :for_kind, ->(kind) { joins(:exam_import).where(exam_imports: { kind: kind }) }
  scope :chronological, -> { order(:exam_date) }

  def percentage
    return nil if max_score.to_f.zero?

    (score.to_f / max_score.to_f * 100).round(1)
  end
end
