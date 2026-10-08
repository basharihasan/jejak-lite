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
  # Kelompok tinjauan untuk radar per kategori — kode dari impor Glide
  # (CbtExam::DIMENSION_CATEGORY_MAP / CATEGORY_META jejak.pro).
  CATEGORY_LABELS = {
    "kompetensi"       => "Area Kompetensi",
    "sistem_organ"     => "Sistem Organ",
    "siklus_kehidupan" => "Siklus Kehidupan",
    "sistem_kesehatan" => "Sistem Kesehatan",
    "proses_klinis"    => "Proses Klinis & Kognitif",
    "patomekanisme"    => "Patomekanisme Penyakit",
    "setting_klinis"   => "Setting Klinis",
    "aspek"            => "Aspek Tinjauan",
    "osce_klinis"      => "Dimensi Klinis OSCE",
    "lainnya"          => "Lainnya"
  }.freeze

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

  def category_label
    CATEGORY_LABELS.fetch(category, category) if category.present?
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
