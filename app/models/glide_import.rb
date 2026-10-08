# frozen_string_literal: true

# Satu unggahan CSV berformat ekspor Glide (CBT Exam Results / Penilaian
# OSCE) — padanan ImportRun jejak.pro: ringkasan hasil, alasan baris
# dilewati, contoh galat, dan dasar rollback.
#
# Rollback hanya membuang apa yang DIBUAT unggahan ini (event, percobaan,
# station OSCE) dan mengembalikan percobaan terdaftar yang diisinya ke
# "Terdaftar". Nilai yang sudah ada sebelumnya tidak pernah ditimpa importer
# Glide, jadi tidak ada yang perlu dipulihkan.
class GlideImport < ApplicationRecord
  IMPORTERS = {
    "cbt"  => { label: "CBT Exam Results", file: "data_cbt_exams_glide.csv", description: "Hasil Ujian CBT & Capaian Kompetensi" },
    "osce" => { label: "OSCE", file: "data_osce_glide.csv", description: "Penilaian OSCE (8 dimensi klinis)" }
  }.freeze
  STATUSES = { "completed" => "Selesai", "rolled_back" => "Di-rollback" }.freeze
  SKIP_REASON_LABELS = {
    "mahasiswa_tidak_ditemukan" => "Mahasiswa tidak ditemukan (email belum terdaftar sebagai mahasiswa)",
    "sudah_diimpor"             => "Sudah diimpor sebelumnya",
    "station_sudah_ada"         => "Station yang sama sudah ada (tanpa $rowID)",
    "nilai_lain_sudah_ada"      => "Mahasiswa sudah punya nilai OSCE dari sumber lain pada event ini",
    "nilai_total_kosong"        => "Nilai total kosong",
    "tanpa_nilai"               => "Tidak ada nilai dimensi maupun global rating"
  }.freeze
  MAX_ERROR_MESSAGES = 50

  belongs_to :imported_by, class_name: "User", optional: true
  belongs_to :rolled_back_by, class_name: "User", optional: true
  has_many :osce_station_scores, dependent: :nullify

  validates :importer_key, inclusion: { in: IMPORTERS.keys }
  validates :status, inclusion: { in: STATUSES.keys }

  scope :recent, -> { order(created_at: :desc) }

  def importer_label = IMPORTERS.dig(importer_key, :label) || importer_key
  def status_label = STATUSES.fetch(status, status)
  def rolled_back? = status == "rolled_back"

  def rollbackable?
    status == "completed" && (created_event_ids.any? || created_instance_ids.any? || filled_instance_ids.any? || osce_station_scores.exists?)
  end

  def events
    AssessmentEvent.where(id: event_ids_touched)
  end

  # Event yang dibuat ATAU diisi unggahan ini (disimpan saat impor).
  def event_ids_touched
    Array(options["event_ids"]).map(&:to_i) | created_event_ids.map(&:to_i)
  end

  def add_error(message)
    self.error_count += 1
    error_messages << message if error_messages.size < MAX_ERROR_MESSAGES
  end

  def add_skip(reason)
    self.skipped_count += 1
    skip_reasons[reason] = skip_reasons.fetch(reason, 0) + 1
  end

  def rollback!(user)
    return false unless rollbackable?

    transaction do
      created_ids = created_instance_ids.map(&:to_i)
      filled_ids = filled_instance_ids.map(&:to_i)
      # Bukan osce_station_scores.delete_all: dengan dependent: :nullify itu
      # hanya melepas tautan, station-nya tetap ada.
      stations = OsceStationScore.where(glide_import_id: id)
      station_instance_ids = stations.distinct.pluck(:assessment_instance_id)
      stations.delete_all

      touched = station_instance_ids | created_ids | filled_ids
      remaining = OsceStationScore.where(assessment_instance_id: touched).distinct.pluck(:assessment_instance_id)
      # Station dari unggahan lain masih ada — rangkum ulang saja.
      OsceStationSummary.refresh!(remaining)
      orphans = touched - remaining
      # Percobaan yang dibuat impor hanya berisi nilai & nilai dimensi (tanpa
      # dokumen/notifikasi), jadi dihapus massal — ribuan destroy satu per
      # satu membuat rollback OSCE penuh memakan lebih dari semenit.
      doomed = orphans & created_ids
      AssessmentDimensionScore.where(assessment_instance_id: doomed).delete_all
      AssessmentInstance.where(id: doomed).delete_all
      AssessmentInstance.where(id: orphans - created_ids).find_each do |instance|
        station_instance_ids.include?(instance.id) ? instance.recalculate_from_osce_stations! : instance.reset_to_registered!
      end

      AssessmentEvent.where(id: created_event_ids).find_each do |event|
        event.destroy! unless event.assessment_instances.exists?
      end

      update!(status: "rolled_back", rolled_back_at: Time.current, rolled_back_by: user)
    end
  end
end
