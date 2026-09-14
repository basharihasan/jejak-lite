# frozen_string_literal: true

# Learning Unit — blok/modul pembelajaran satu prodi (opsional terikat satu
# periode). Nilai akhirnya disusun dari beberapa Assessment Event lewat
# Assessment Matrix (AssessmentMapping) dengan bobot. Padanan ringan
# "Assessment Matrix per Learning Unit" jejak.pro; tanpa Curriculum Blueprint
# (Fase/Unit) yang sengaja tidak dibawa ke tier Dasar.
class LearningUnit < ApplicationRecord
  belongs_to :study_program
  belongs_to :academic_period, optional: true
  belongs_to :assessment_blueprint, optional: true

  has_many :assessment_mappings, dependent: :destroy
  has_many :assessment_events, through: :assessment_mappings

  validates :name, presence: true
  validates :name, uniqueness: { scope: %i[study_program_id academic_period_id], message: "sudah ada untuk prodi & periode ini" }
  validates :credits, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:study_program_id, :name) }
  scope :for_student, ->(user) { where(study_program_id: user.study_program_id) }

  def total_weight
    assessment_mappings.sum { |m| m.weight.to_f }
  end

  def weights_complete?
    (total_weight - 100).abs < 0.01
  end

  # Nilai unit seorang mahasiswa: rata-rata TERBOBOT persentase tiap event
  # (percobaan wakil per event, lihat AssessmentInstance.representative_for).
  # Event yang belum punya nilai dilewati, dan bobotnya tidak ikut menjadi
  # penyebut — jadi angka ini "capaian dari yang sudah dinilai", bukan nilai
  # akhir sebelum semua komponen masuk.
  def score_for(student)
    weighted = 0.0
    weight_used = 0.0
    components_for(student).each do |row|
      next if row[:percentage].nil?

      weighted += row[:percentage] * row[:weight]
      weight_used += row[:weight]
    end
    return nil if weight_used.zero?

    { percentage: (weighted / weight_used).round(1), weight_covered: weight_used.round(1) }
  end

  def components_for(student)
    assessment_mappings.includes(:assessment_event).map do |mapping|
      instance = AssessmentInstance.representative_for(mapping.assessment_event, student)
      { event: mapping.assessment_event, weight: mapping.weight.to_f, instance: instance, percentage: instance&.percentage }
    end
  end
end
