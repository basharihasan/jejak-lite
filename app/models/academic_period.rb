# frozen_string_literal: true

class AcademicPeriod < ApplicationRecord
  # Periode yang sudah dipakai tidak bisa dihapus — dulu rotasi klinis ikut
  # terhapus berantai (beserta tautan DOPS/Mini-CEX-nya), dan tabel lain yang
  # menunjuk periode membuat penghapusan gagal dengan galat 500.
  IN_USE_LABELS = {
    clinical_rotations: "rotasi klinis", tutorial_enrollments: "enrolmen tutorial",
    assessment_events: "assessment event", competency_milestones: "target milestone kompetensi",
    learning_units: "unit pembelajaran", logbook_case_targets: "target kasus logbook"
  }.freeze

  has_many :clinical_rotations, dependent: :restrict_with_error
  has_many :tutorial_enrollments, dependent: :restrict_with_error
  has_many :assessment_events, dependent: :restrict_with_error
  has_many :competency_milestones, dependent: :restrict_with_error
  has_many :learning_units, dependent: :restrict_with_error
  has_many :logbook_case_targets, dependent: :restrict_with_error
  has_many :activity_logs, dependent: :nullify

  validates :name, :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :ordered, -> { order(start_date: :desc) }

  # "3 rotasi klinis dan 1 assessment event" — untuk pesan gagal hapus.
  def usage_summary
    IN_USE_LABELS.filter_map do |association, label|
      count = public_send(association).count
      "#{count} #{label}" if count.positive?
    end.to_sentence
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "harus setelah tanggal mulai") if end_date <= start_date
  end
end
