# frozen_string_literal: true

# Satu station OSCE yang diuji seorang mahasiswa — satu baris tabel
# "Penilaian OSCE" Glide (data_osce_glide.csv). Delapan dimensi klinis
# dinilai 0–3; nilai checklist = rata-rata dimensi yang terisi ÷ 3 × 100,
# sama seperti OsceGlideImporter jejak.pro (bobot station = 1).
#
# Nilai OSCE mahasiswa pada event (AssessmentInstance) adalah rangkuman semua
# station-nya — lihat AssessmentInstance#recalculate_from_osce_stations!.
class OsceStationScore < ApplicationRecord
  # kunci kolom Glide (dinormalisasi) => label
  DIMENSIONS = {
    "anamnesis"                   => "Anamnesis",
    "pemeriksaanfisik"            => "Pemeriksaan Fisik",
    "interpretasidata"            => "Interpretasi Data",
    "penegakandiagnosis"          => "Penegakan Diagnosis",
    "tatalaksananonfarmakoterapi" => "Tatalaksana Non-Farmakoterapi",
    "tatalaksanafarmakoterapi"    => "Tatalaksana Farmakoterapi",
    "komunikasidanedukasipasien"  => "Komunikasi & Edukasi Pasien",
    "perilakuprofesional"         => "Perilaku Profesional"
  }.freeze
  MAX_DIMENSION_SCORE = 3
  # Nilai global rating di data Glide nyata: Fail / Borderline / Good / Superior.
  GLOBAL_RATING_TONES = {
    "fail" => "bg-rose-50 text-rose-700", "borderline" => "bg-amber-50 text-amber-700",
    "good" => "bg-emerald-50 text-emerald-700", "superior" => "bg-indigo-50 text-indigo-700"
  }.freeze

  belongs_to :assessment_instance
  belongs_to :examiner, class_name: "User", optional: true
  belongs_to :glide_import, optional: true

  validates :checklist_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :scores_within_scale

  scope :ordered, -> { order(:assessed_at, :station, :id) }
  scope :for_event, ->(event) { joins(:assessment_instance).where(assessment_instances: { assessment_event_id: event.id }) }

  # Rata-rata dimensi terisi dalam persen (0–100); nil bila tak ada dimensi.
  def self.checklist_from(scores)
    values = scores.to_h.values.compact.map(&:to_f)
    return nil if values.empty?

    (values.sum / (values.size * MAX_DIMENSION_SCORE) * 100).round(2)
  end

  def label
    [ station.present? ? "Station #{station}" : "Station", case_title.presence ].compact.join(" — ")
  end

  def score_for(key)
    scores.to_h[key.to_s]
  end

  def global_rating_tone
    GLOBAL_RATING_TONES.fetch(global_rating.to_s.downcase, "bg-gray-100 text-gray-600")
  end

  def has_feedback?
    feedback_keep.present? || feedback_improve.present?
  end

  private

  def scores_within_scale
    scores.to_h.each do |key, value|
      next if value.nil?
      next if value.to_f.between?(0, MAX_DIMENSION_SCORE)

      errors.add(:scores, "#{DIMENSIONS.fetch(key, key)} harus 0–#{MAX_DIMENSION_SCORE}")
    end
  end
end
