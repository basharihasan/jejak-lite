# frozen_string_literal: true

# Satu percobaan seorang mahasiswa pada satu AssessmentEvent. Event yang
# mengizinkan percobaan berulang punya beberapa baris per mahasiswa
# (attempt_number), unik per (event, mahasiswa, percobaan) — pakai
# `representative_for`, bukan find_by, saat butuh satu nilai wakil.
class AssessmentInstance < ApplicationRecord
  STATUSES = { "registered" => "Terdaftar", "submitted" => "Dikumpulkan", "scored" => "Dinilai" }.freeze
  SOURCES = %w[import manual rubric].freeze

  belongs_to :assessment_event
  belongs_to :student, class_name: "User"
  belongs_to :examiner, class_name: "User", optional: true
  belongs_to :clinical_case, optional: true
  belongs_to :assessment_form_submission, optional: true

  has_many :assessment_dimension_scores, dependent: :destroy
  has_many :assessment_dimensions, through: :assessment_dimension_scores

  has_one_attached :document

  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 }
  validates :attempt_number, uniqueness: { scope: %i[assessment_event_id student_id] }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :source, inclusion: { in: SOURCES }
  validates :score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_score, numericality: { greater_than: 0 }
  validate :score_within_max

  scope :scored, -> { where(status: "scored") }
  scope :by_attempt, -> { order(:attempt_number) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_examiner, ->(user) { where(examiner: user) }
  scope :awaiting_score, -> { where.not(status: "scored") }
  scope :in_period, ->(period) { joins(:assessment_event).where(assessment_events: { academic_period_id: period.id }) }
  scope :of_type, ->(t) { joins(:assessment_event).where(assessment_events: { assessment_type: t }) }

  delegate :type_label, :family, :assessment_type, to: :assessment_event

  def status_label = STATUSES.fetch(status, status)

  def percentage
    return nil if score.nil? || max_score.to_f.zero?

    (score.to_f / max_score.to_f * 100).round(1)
  end

  # Tanggal yang dipakai grafik/kurva: waktu dinilai, jatuh ke tanggal ujian event.
  def effective_date
    (scored_at || submitted_at || assessment_event.exam_date || created_at).to_date
  end

  # Nilai wakil per (event, mahasiswa): percobaan bernilai tertinggi; kalau
  # belum ada yang dinilai, percobaan terbaru.
  def self.representative_for(event, student)
    rows = where(assessment_event: event, student: student).to_a
    rows.select(&:score).max_by(&:score) || rows.max_by(&:attempt_number)
  end

  def self.next_attempt_number(event, student)
    (where(assessment_event: event, student: student).maximum(:attempt_number) || 0) + 1
  end

  def submit!(document: nil, self_evaluation: nil)
    self.document.attach(document) if document.present?
    update!(self_evaluation: self_evaluation.presence || self.self_evaluation, status: "submitted", submitted_at: Time.current)
  end

  def score!(score:, examiner:, feedback_keep: nil, feedback_improve: nil, source: "manual")
    update!(score: score, examiner: examiner, feedback_keep: feedback_keep, feedback_improve: feedback_improve,
            status: "scored", scored_at: Time.current, source: source)
    Notification.notify!(
      recipient: student, sender: examiner, notifiable: self,
      title: "Nilai #{type_label} sudah keluar", message: "#{assessment_event.name}: #{score}/#{max_score}"
    )
  end

  # Nilai total dari nilai per dimensi: rata-rata TERBOBOT persentase tiap
  # dimensi yang terisi × nilai maksimum event. Dimensi yang tidak diimpor
  # tidak ikut menjadi penyebut.
  def recalculate_from_dimensions!
    rows = assessment_dimension_scores.includes(:assessment_dimension).to_a
    return nil if rows.empty?

    weighted = 0.0
    total_weight = 0.0
    rows.each do |row|
      percentage = row.percentage
      next if percentage.nil?

      weight = row.weight.to_f
      weighted += percentage * weight
      total_weight += weight
    end
    return nil if total_weight.zero?

    update!(score: ((weighted / total_weight) / 100.0 * max_score).round(2))
  end

  def dimension_scores_by_competency
    assessment_dimension_scores.includes(assessment_dimension: :competency_item)
                               .select { |row| row.competency_item.present? }
                               .group_by(&:competency_item)
  end

  def has_feedback?
    feedback_keep.present? || feedback_improve.present?
  end

  private

  def score_within_max
    return if score.nil? || max_score.nil?

    errors.add(:score, "tidak boleh melebihi nilai maksimum (#{max_score})") if score > max_score
  end
end
