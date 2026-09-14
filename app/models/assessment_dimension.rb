# frozen_string_literal: true

# Satu dimensi penilaian pada sebuah Assessment Event:
#   - CBT  → mata uji / tinjauan ("Penalaran Klinis", "Literasi Sains")
#   - OSCE → station ("Station 3 — Anamnesis & Komunikasi")
#
# `competency_item` adalah pemetaan dimensi → ranah kompetensi. Dari sinilah
# Peta Kompetensi terisi oleh hasil ujian yang sebenarnya; dimensi yang belum
# dipetakan tetap dihitung untuk nilai total, tetapi TIDAK ikut ke peta
# kompetensi — lebih baik kosong daripada salah atribusi.
class AssessmentDimension < ApplicationRecord
  belongs_to :assessment_event
  belongs_to :competency_item, optional: true
  has_many :assessment_dimension_scores, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :assessment_event_id, case_sensitive: false, message: "sudah ada pada event ini" }
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :max_score, numericality: { greater_than: 0 }

  before_create :assign_position

  scope :ordered, -> { order(:position, :id) }
  scope :mapped, -> { where.not(competency_item_id: nil) }

  def label
    [ code.presence, name ].compact.join(" — ")
  end

  def mapped?
    competency_item_id.present?
  end

  def percentage_of(score)
    return nil if score.blank? || max_score.to_f.zero?

    (score.to_f / max_score.to_f * 100).round(1)
  end

  private

  def assign_position
    self.position = (assessment_event.assessment_dimensions.maximum(:position) || 0) + 1
  end
end
