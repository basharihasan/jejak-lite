# frozen_string_literal: true

require "csv"

# Konfigurasi → Impor CBT & OSCE (CSV Glide): unggah berkas .csv hasil ekspor
# tabel Glide — "CBT Exam Results" (data_cbt_exams_glide.csv) atau "Penilaian
# OSCE" (data_osce_glide.csv) — tanpa koneksi API Glide. Padanan
# /admin/glide_syncs/csv_import jejak.pro; diproses langsung (bukan job latar)
# lalu diarahkan ke ringkasan hasil, yang juga menjadi tempat rollback.
class Admin::GlideSyncsController < Admin::BaseController
  MAX_FILE_SIZE = 50.megabytes

  # Kolom contoh templat. CBT: ekspor hasil ujian per sesi (kolom dimensi
  # berprefiks kelompok); format Glide lama (email, exam_code, …) tetap
  # diterima importer. OSCE: urutan dan ejaan persis ekspor Glide.
  TEMPLATES = {
    "cbt" => {
      headers: [ "Nomor Ujian", "Nama Peserta", "email", "Tanggal", "Sesi", "Jumlah Benar", "Jumlah Raw Nilai", "Nilai Akhir",
                 "[AK] Komunikasi efektif", "[AK] Keterampilan klinis", "[ST] Respirasi", "[ST] Kardiovaskular",
                 "[TK] 3A", "[TK] 4A", "[KAT] Adult", "[KAT] Hospital", "[KAT] Knowledge" ],
      example: [ "", "Contoh Mahasiswa", "mahasiswa@kampus.ac.id", "6 Juni 2026", "Sesi 1", "54", "54", "72,00",
                 "80", "65,22", "70", "75,5", "100", "60", "72,5", "68", "70" ]
    },
    "osce" => {
      headers: [ "rowID", "emailYangDiuji", "namaYangDiuji", "emailPenguji", "namaPenguji", "tanggalEntry", "station", "kasus", "IDSoal",
                 "Anamnesis", "PemeriksaanFisik", "InterpretasiData", "PenegakanDiagnosis", "TatalaksanaNonFarmakoterapi",
                 "TatalaksanaFarmakoterapi", "KomunikasiDanEdukasiPasien", "PerilakuProfesional",
                 "globalRating", "halBaik", "perluDitingkatkan", "refleksi" ],
      example: [ "contoh-001", "mahasiswa@kampus.ac.id", "Contoh Mahasiswa", "penguji@kampus.ac.id", "dr. Contoh Penguji",
                 "2025-10-20T02:30:00.000Z", "1", "Demam berdarah dengue", "S01",
                 "3", "2", "2", "3", "", "3", "2", "3", "Good", "Anamnesis runtut", "Edukasi pasien", "" ]
    }
  }.freeze

  def index
    @imports = GlideImport.recent.includes(:imported_by).page(params[:page]).per(20)
  end

  def show
    @import = GlideImport.find(params[:id])
    @events = @import.events.includes(:academic_period).ordered.limit(100)
  end

  def csv_import
    load_form_collections
  end

  def process_csv_import
    file = params[:csv_file]
    importer_key = params[:importer_type].to_s
    return redirect_back_to_form("Pilih tipe data: CBT Exam Results atau OSCE.") unless GlideImport::IMPORTERS.key?(importer_key)
    return redirect_back_to_form("Pilih berkas CSV terlebih dahulu.") unless file.respond_to?(:read)
    return redirect_back_to_form("Berkas harus berekstensi .csv (ekspor CSV Glide / Excel → CSV).") unless File.extname(file.original_filename.to_s).casecmp?(".csv")
    return redirect_back_to_form("Berkas lebih dari 50 MB.") if file.size > MAX_FILE_SIZE

    target_event = nil
    if importer_key == "osce" && params[:target_event_id].present?
      target_event = AssessmentEvent.of_type("osce").find_by(id: params[:target_event_id])
      return redirect_back_to_form("Event OSCE tujuan tidak ditemukan.") if target_event.nil?
    end
    exam_date = parse_exam_date
    return redirect_back_to_form("Tanggal ujian tidak valid.") if exam_date == :invalid

    import = GlideImport.create!(
      importer_key: importer_key, filename: file.original_filename, imported_by: current_user,
      options: { "exam_title" => params[:exam_title].presence, "exam_date" => exam_date&.iso8601,
                 "study_program_id" => study_program&.id, "academic_period_id" => academic_period&.id,
                 "target_event_id" => target_event&.id }.compact
    )
    common = { csv_text: file.read, glide_import: import, user: current_user, study_program: study_program, academic_period: academic_period }
    if importer_key == "cbt"
      CbtGlideImporter.new(**common, exam_title: params[:exam_title], exam_date: exam_date).call
    else
      OsceGlideImporter.new(**common, target_event: target_event).call
    end

    redirect_to admin_glide_sync_path(import), notice: summary_notice(import)
  end

  # GET /admin/glide_syncs/template.csv?type=cbt|osce — header persis ekspor
  # Glide + satu baris contoh, BOM di depan supaya Excel membaca UTF-8.
  def template
    template = TEMPLATES[params[:type].to_s]
    return redirect_to(csv_import_admin_glide_syncs_path, alert: "Tipe templat tidak dikenal.") if template.nil?

    csv = CSV.generate { |rows| rows << template[:headers] << template[:example] }
    send_data "﻿#{csv}", filename: GlideImport::IMPORTERS.dig(params[:type], :file).sub(".csv", "_template.csv"),
                              type: "text/csv; charset=utf-8"
  end

  def rollback
    import = GlideImport.find(params[:id])
    if import.rollback!(current_user)
      redirect_to admin_glide_sync_path(import), notice: "Unggahan ##{import.id} di-rollback: nilai yang dibuatnya sudah dihapus."
    else
      redirect_to admin_glide_sync_path(import), alert: "Unggahan ##{import.id} tidak dapat di-rollback (sudah di-rollback atau tidak membuat data)."
    end
  end

  private

  def load_form_collections
    @study_programs = StudyProgram.ordered
    @academic_periods = AcademicPeriod.ordered
    @osce_events = AssessmentEvent.of_type("osce").includes(:academic_period).ordered.limit(200)
  end

  def redirect_back_to_form(message)
    redirect_to csv_import_admin_glide_syncs_path, alert: message
  end

  def study_program
    @study_program ||= StudyProgram.find_by(id: params[:study_program_id]) if params[:study_program_id].present?
  end

  def academic_period
    @academic_period ||= AcademicPeriod.find_by(id: params[:academic_period_id]) if params[:academic_period_id].present?
  end

  def parse_exam_date
    return nil if params[:exam_date].blank?

    Date.iso8601(params[:exam_date].to_s)
  rescue Date::Error
    :invalid
  end

  def summary_notice(import)
    if import.importer_key == "osce"
      "Impor OSCE selesai: #{import.created_count} station masuk, #{import.skipped_count} dilewati, #{import.error_count} galat."
    else
      "Impor CBT selesai: #{import.created_count + import.updated_count} nilai masuk, #{import.skipped_count} dilewati, #{import.error_count} galat."
    end
  end
end
