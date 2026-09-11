# frozen_string_literal: true

class AcademicPeriod < ApplicationRecord
  has_many :clinical_rotations, dependent: :destroy

  validates :name, :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :ordered, -> { order(start_date: :desc) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "harus setelah tanggal mulai") if end_date <= start_date
  end
end
