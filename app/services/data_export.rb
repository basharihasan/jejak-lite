# frozen_string_literal: true

require "csv"

# Pusat Ekspor Data (/admin/exports): unduhan CSV data operasional untuk
# admin (seluruh instalasi) dan kaprodi (mahasiswa prodi binaannya).
#
# Setiap dataset di DATASETS menyatakan kolom dan filter yang berlaku;
# isinya dibangun pasangan metode privat <kunci>_scope (relasi yang sudah
# disaring) dan <kunci>_row (satu rekaman → satu baris).
#
# Cakupan prodi ditegakkan DI SINI, bukan di controller: kaprodi yang terikat
# prodi (User#study_program_bound?) selalu dikunci ke prodi akunnya, apa pun
# parameter yang dikirim — sama dengan Analitik dan Jadwal DOPS & Mini-CEX.
#
# Sengaja tidak pernah ikut ekspor:
#   - identitas pasien terenkripsi (ClinicalCase::SENSITIVE_PATIENT_FIELDS) —
#     paket migrasi tetap satu-satunya jalur, dan itu pun harus diminta;
#   - refleksi pribadi (ReflectionEntry & kolom refleksi Logbook Kegiatan) —
#     di aplikasi hanya pemiliknya yang membacanya;
#   - rahasia akun (kata sandi, token) dan kode pasien logbook.
class DataExport
  class AccessDenied < StandardError; end

  Dataset = Data.define(:key, :label, :description, :group, :headers, :filters, :admin_only) do
    def filter?(name) = filters.include?(name)
  end

  GROUPS = {
    people: "Mahasiswa & Pengguna",
    learning: "Perjalanan Belajar",
    assessment: "Asesmen & Kompetensi",
    master: "Master Data"
  }.freeze

  FILTER_LABELS = { program: "Prodi", period: "Periode", dates: "Tanggal", form_template: "Formulir" }.freeze

  # standard: koma & titik desimal (Google Sheets, LibreOffice, skrip).
  # excel_id: titik koma & koma desimal — Excel berpengaturan regional
  # Indonesia membaca koma sebagai desimal, jadi CSV berkoma tampil satu
  # kolom. NPM & telepon ditulis sebagai teks (EXCEL_TEXT_NUMBER).
  FORMATS = {
    "standard" => "Standar (koma)",
    "excel_id" => "Excel Indonesia (titik koma)"
  }.freeze

  STUDENT_HEADERS = [ "Nama Mahasiswa", "Email Mahasiswa", "NPM / NIM", "Program Studi" ].freeze

  DATASETS = [
    Dataset.new(
      key: "students", label: "Data Mahasiswa", group: :people, filters: %i[program], admin_only: false,
      description: "Satu baris per mahasiswa: identitas akademik, angkatan, kontak, dan aktivitas login.",
      headers: [ "Nama", "Email", "NPM / NIM", "Program Studi", "Jenjang", "Angkatan", "Jenis Kelamin", "Telepon",
                 "Login Terakhir", "Jumlah Login", "Terdaftar Sejak" ]
    ),
    Dataset.new(
      key: "student_summary", label: "Rekap Capaian per Mahasiswa", group: :people, filters: %i[program period dates], admin_only: false,
      description: "Satu baris per mahasiswa: jumlah kegiatan & kasus, rata-rata DOPS/Mini-CEX, nilai asesmen, ranah EPA berlevel, dan status tugas akhir.",
      headers: [ "Nama", "Email", "NPM / NIM", "Program Studi", "Angkatan", "Kegiatan", "Kegiatan Terverifikasi",
                 "Kasus Diajukan", "Kasus Terverifikasi", "DOPS Terkirim", "Rata-rata DOPS", "Mini-CEX Terkirim",
                 "Rata-rata Mini-CEX", "Event Asesmen Dinilai", "Rata-rata Nilai Asesmen (%)", "Ranah EPA Berlevel",
                 "Status Tugas Akhir" ]
    ),
    Dataset.new(
      key: "users", label: "Pengguna & Peran", group: :people, filters: %i[program], admin_only: true,
      description: "Seluruh akun beserta perannya. Empat kolom pertama berformat Impor CSV Pengguna, jadi berkasnya bisa diimpor ulang.",
      headers: [ "email", "nama", "peran", "prodi", "NIP / NIDN / NPM", "Peran Aktif", "Unit Kerja", "Jabatan",
                 "Kategori Profesi", "Spesialisasi", "Telepon", "Login Terakhir", "Terdaftar Sejak" ]
    ),
    Dataset.new(
      key: "activity_logs", label: "Logbook Kegiatan", group: :learning, filters: %i[program period dates], admin_only: false,
      description: "Setiap kegiatan beserta taksonomi, waktu, lokasi, dan status verifikasinya. Kolom refleksi tidak ikut.",
      headers: [ "Tanggal", "Waktu Mulai", "Waktu Selesai", *STUDENT_HEADERS, "Domain", "Subdomain / Kategori",
                 "Bentuk Kegiatan", "Klinis/Non-Klinis", "Topik", "Lokasi", "Metode", "Jumlah Peserta", "Semester",
                 "Rotasi", "Catatan", "Status Verifikasi", "Diverifikasi Oleh", "Waktu Verifikasi", "Link Bukti",
                 "Link Dokumen" ]
    ),
    Dataset.new(
      key: "clinical_cases", label: "Kasus Klinis", group: :learning, filters: %i[program period dates], admin_only: false,
      description: "Ringkasan setiap kasus: diagnosis, ICD-10, SKDI, status verifikasi, dan tingkat entrustment. Identitas pasien tidak pernah ikut; draf hanya untuk admin.",
      headers: [ "ID Kasus", "Tanggal", *STUDENT_HEADERS, "Status", "Keluhan Utama", "Diagnosis", "Kode ICD-10",
                 "Level SKDI", "Setting Klinik", "Kompleksitas", "Kelompok Usia Pasien", "Jenis Kelamin Pasien",
                 "Usia Pasien", "Pembimbing Ditandai", "Diverifikasi Oleh", "Waktu Verifikasi", "Tingkat Entrustment",
                 "Rekomendasi Remediasi" ]
    ),
    Dataset.new(
      key: "clinical_rotations", label: "Rotasi Klinik", group: :learning, filters: %i[program period dates], admin_only: false,
      description: "Penempatan stase mahasiswa: wahana, periode, tanggal, dan preseptor.",
      headers: [ *STUDENT_HEADERS, "Stase / Blok Klinis", "Wahana", "Periode", "Mulai", "Selesai", "Status",
                 "Preseptor", "Email Preseptor" ]
    ),
    Dataset.new(
      key: "tutorial_enrollments", label: "Enrolment Tutorial", group: :learning, filters: %i[program period dates], admin_only: false,
      description: "Pendaftaran blok/sistem tutorial: kelompok, periode, dan dosen tutor.",
      headers: [ *STUDENT_HEADERS, "Blok / Sistem", "Kelompok", "Periode", "Mulai", "Selesai", "Tutor", "Email Tutor", "Status" ]
    ),
    Dataset.new(
      key: "final_projects", label: "Tugas Akhir", group: :learning, filters: %i[program], admin_only: false,
      description: "Judul, status, pembimbing, kemajuan milestone, dan rata-rata nilai penguji.",
      headers: [ *STUDENT_HEADERS, "Judul", "Status", "Pembimbing", "Milestone Selesai", "Jumlah Milestone",
                 "Jumlah Nilai Penguji", "Rata-rata Nilai Penguji", "Dibuat" ]
    ),
    Dataset.new(
      key: "dops_evaluations", label: "DOPS", group: :assessment, filters: %i[program period dates], admin_only: false,
      description: "Setiap penilaian DOPS: prosedur, penilai, skor per dimensi (1–9), rata-rata, dan umpan balik.",
      headers: [ "Tanggal", *STUDENT_HEADERS, "Penilai", "Stase", "Prosedur", "Status", "Setting Klinik", "Kompleksitas",
                 "Kelompok Usia Pasien", "Observasi (menit)", "Umpan Balik (menit)", *DopsEvaluation::DIMENSIONS.values,
                 "Rata-rata Skor", "Umpan Balik" ]
    ),
    Dataset.new(
      key: "mini_cex_evaluations", label: "Mini-CEX", group: :assessment, filters: %i[program period dates], admin_only: false,
      description: "Setiap penilaian Mini-CEX: kasus, penilai, skor per dimensi (1–9), penilaian global, dan umpan balik.",
      headers: [ "Tanggal", *STUDENT_HEADERS, "Penilai", "Stase", "Deskripsi Kasus", "Status", "Setting Klinik", "Kompleksitas",
                 "Kelompok Usia Pasien", "Observasi (menit)", "Umpan Balik (menit)", *MiniCexEvaluation::DIMENSIONS.values,
                 "Rata-rata Skor", "Penilaian Global", "Umpan Balik" ]
    ),
    Dataset.new(
      key: "assessment_scores", label: "Nilai Event Asesmen", group: :assessment, filters: %i[program period dates], admin_only: false,
      description: "Setiap percobaan CBT, OSCE, Progress Test, rubrik, CBD/Long Case: nilai, persentase, penguji, dan umpan balik.",
      headers: [ "Event Asesmen", "Tipe", "Periode", "Prodi Event", "Blok / Stase", "Tanggal Ujian", *STUDENT_HEADERS,
                 "Percobaan", "Status", "Nilai", "Nilai Maks", "Persentase", "Penguji", "Waktu Dinilai", "Sumber Nilai",
                 "Umpan Balik (Pertahankan)", "Umpan Balik (Perbaiki)" ]
    ),
    Dataset.new(
      key: "entrustment_decisions", label: "Keputusan Entrustment EPA", group: :assessment, filters: %i[program period dates], admin_only: false,
      description: "Riwayat lengkap keputusan level EPA 1–5, termasuk yang sudah tergantikan atau dicabut.",
      headers: [ "Tanggal Keputusan", *STUDENT_HEADERS, "Kerangka Kompetensi", "Ranah / EPA", "Level", "Keterangan Level",
                 "Justifikasi", "Diputuskan Oleh", "ID Kasus Klinis", "Status Keputusan" ]
    ),
    Dataset.new(
      key: "evaluation_schedules", label: "Jadwal DOPS & Mini-CEX", group: :assessment, filters: %i[program period dates], admin_only: false,
      description: "Rencana penilaian di tempat kerja beserta penilai dan statusnya.",
      headers: [ "Waktu", "Jenis", *STUDENT_HEADERS, "Penilai", "Stase", "Topik", "Status", "Catatan" ]
    ),
    Dataset.new(
      key: "form_answers", label: "Jawaban Assessment Form", group: :assessment, filters: %i[period dates form_template], admin_only: false,
      description: "Satu baris per jawaban pertanyaan Form Builder. Responden formulir anonim hanya tampil untuk admin.",
      headers: [ "Formulir", "ID Pengisian", "Waktu Pengisian", "Responden", "Email Responden", "Subjek", "Pertanyaan",
                 "Jenis Pertanyaan", "Jawaban", "Skor (%)" ]
    ),
    Dataset.new(
      key: "diagnosis_definitions", label: "Master Diagnosis", group: :master, filters: [], admin_only: true,
      description: "Daftar diagnosis. Header sama dengan impor master data, jadi bisa disunting lalu diimpor ulang.",
      headers: %w[name icd10_code skdi_level system_group active]
    ),
    Dataset.new(
      key: "skill_definitions", label: "Master Keterampilan", group: :master, filters: [], admin_only: true,
      description: "Daftar keterampilan klinis. Header sama dengan impor master data.",
      headers: %w[name category skdi_level active]
    ),
    Dataset.new(
      key: "medication_definitions", label: "Master Obat", group: :master, filters: [], admin_only: true,
      description: "Daftar obat untuk latihan resep. Header sama dengan impor master data.",
      headers: %w[name category strength dosage_form usual_dosage active]
    )
  ].index_by(&:key).freeze

  ASSESSMENT_SOURCES = { "import" => "Impor CSV", "manual" => "Manual", "rubric" => "Rubrik penguji" }.freeze
  BATCH_SIZE = 500
  # Sel yang diawali karakter ini dijalankan sebagai rumus oleh Excel/Sheets
  # (CSV injection) — teks bebas mahasiswa tidak boleh menjadi rumus di
  # komputer kaprodi. Angka/telepon (+62 …, -5) dibiarkan apa adanya.
  FORMULA_TRIGGER = /\A(?:[=@\t\r]|[+-](?![\d\s().\-]*\z))/
  # Excel membuang nol/plus di depan dan menyingkat angka panjang (NPM,
  # telepon) menjadi 1,3E+11 — format Excel menuliskannya sebagai teks ="…".
  EXCEL_TEXT_NUMBER = /\A(?:\+\d+|0\d+|\d{12,})\z/

  def self.allowed?(user)
    user.has_role?("admin") || user.has_role?("kaprodi")
  end

  def self.datasets_for(user)
    return [] unless allowed?(user)

    admin = user.has_role?("admin")
    DATASETS.values.reject { |dataset| dataset.admin_only && !admin }
  end

  def self.dataset_for(key, user)
    datasets_for(user).find { |dataset| dataset.key == key.to_s }
  end

  attr_reader :dataset, :study_program, :period, :form_template, :row_count

  def initialize(key, viewer:, study_program_id: nil, academic_period_id: nil, from: nil, to: nil,
                 form_template_id: nil, format: "standard")
    @dataset = self.class.dataset_for(key, viewer) or raise AccessDenied, "Dataset tidak tersedia untuk akun ini."
    @viewer = viewer
    @admin = viewer.has_role?("admin")
    @study_program = resolve_study_program(study_program_id) if @dataset.filter?(:program)
    @period = AcademicPeriod.find_by(id: academic_period_id) if academic_period_id.present? && @dataset.filter?(:period)
    @from, @to = (@dataset.filter?(:dates) ? [ from, to ] : [ nil, nil ])
    @form_template = AssessmentFormTemplate.find_by(id: form_template_id) if form_template_id.present? && @dataset.filter?(:form_template)
    @format = FORMATS.key?(format.to_s) ? format.to_s : "standard"
  end

  # Jumlah baris yang akan diunduh — pratinjau di kartu dataset.
  def count
    respond_to?("#{dataset.key}_count", true) ? send("#{dataset.key}_count") : send("#{dataset.key}_scope").count
  end

  # BOM di depan supaya Excel membaca UTF-8 (nama beraksen, "–", "°").
  def to_csv
    @row_count = 0
    body = CSV.generate(col_sep: excel_id? ? ";" : ",") do |csv|
      csv << dataset.headers
      each_row do |row|
        csv << row.map { |value| cell(value) }
        @row_count += 1
      end
    end
    "﻿#{body}"
  end

  def filename
    parts = [ "jejak", dataset.label.parameterize ]
    parts << (study_program ? (study_program.code.presence || study_program.name.parameterize) : "semua-prodi") if dataset.filter?(:program)
    parts << period.name.parameterize if period
    parts << Date.current.iso8601
    "#{parts.join('-')}.csv"
  end

  # Ringkasan filter untuk jejak audit (DataExportLog#filters).
  def applied_filters
    {
      "prodi" => (study_program&.name || ("Semua prodi" if dataset.filter?(:program))),
      "periode" => period&.name,
      "dari" => @from&.iso8601,
      "sampai" => @to&.iso8601,
      "formulir" => form_template&.name,
      "format" => @format
    }.compact
  end

  private

  def excel_id? = @format == "excel_id"

  # Kaprodi terikat selalu prodinya sendiri; parameter study_program_id
  # hanya didengar dari admin. Kaprodi tanpa prodi ditolak, bukan dibiarkan
  # melihat semua prodi.
  def resolve_study_program(requested_id)
    if @viewer.study_program_bound?
      @viewer.study_program or raise AccessDenied, "Akun kaprodi belum terhubung ke Program Studi."
    elsif requested_id.present?
      StudyProgram.find_by(id: requested_id)
    end
  end

  def each_row(&block)
    if respond_to?("#{dataset.key}_rows", true)
      send("#{dataset.key}_rows", &block)
    else
      each_record(send("#{dataset.key}_scope")) { |record| yield send("#{dataset.key}_row", record) }
    end
  end

  # Urutan (mis. per tanggal) dipertahankan tanpa memuat seluruh rekaman
  # sekaligus: id diambil terurut, rekamannya dimuat per potongan.
  def each_record(relation, &block)
    relation.ids.each_slice(BATCH_SIZE) do |ids|
      relation.unscope(:order).where(id: ids).index_by(&:id).values_at(*ids).each(&block)
    end
  end

  # ── Penyaring bersama ──

  def program_students
    students = User.where(id: UserRole.joins(:role).where(roles: { code: "mahasiswa" }).select(:user_id))
    study_program ? students.where(study_program_id: study_program.id) : students
  end

  # Tanpa prodi terpilih (admin, "Semua prodi") rekaman tidak disaring sama
  # sekali — termasuk milik akun non-mahasiswa yang kebetulan mengisi logbook.
  def within_program(relation, column)
    return relation unless study_program

    relation.where(column => program_students.select(:id))
  end

  # Isian Dari/Sampai; untuk dataset tanpa kolom periode, rentang periode
  # terpilih menjadi rentang tanggalnya (sama dengan Dashboard Analitik).
  def date_range(include_period: true)
    from = @from || (period&.start_date if include_period)
    to = @to || (period&.end_date if include_period)
    (from..to) if from || to
  end

  def within_dates(relation, column, time: false, include_period: true)
    range = date_range(include_period: include_period)
    return relation unless range

    range = (range.begin&.in_time_zone)..(range.end&.in_time_zone&.end_of_day) if time
    relation.where(column => range)
  end

  def within_period(relation, column)
    period ? relation.where(column => period.id) : relation
  end

  # Penempatan (rotasi/tutorial) yang bersinggungan dengan rentang Dari/Sampai.
  def overlapping_dates(relation)
    range = date_range(include_period: false)
    return relation unless range

    table = relation.arel_table
    relation = relation.where(table[:end_date].eq(nil).or(table[:end_date].gteq(range.begin))) if range.begin
    relation = relation.where(table[:start_date].eq(nil).or(table[:start_date].lteq(range.end))) if range.end
    relation
  end

  def student_cells(user)
    [ user.full_name, user.email, user.identifier_number, user.study_program&.name ]
  end

  def label_for(options, value)
    options.fetch(value, value)
  end

  def average(values)
    values = values.compact
    (values.sum.to_f / values.size).round(1) if values.any?
  end

  # ── Mahasiswa & Pengguna ──

  def students_scope
    program_students.includes(:study_program).order(:full_name, :id)
  end

  def students_row(user)
    [ user.full_name, user.email, user.identifier_number, user.study_program&.name, user.study_program&.level_label,
      user.cohort_year, user.gender, user.phone, user.last_sign_in_at, user.sign_in_count, user.created_at.to_date ]
  end

  def users_scope
    users = User.includes(:roles, :study_program, :active_role).order(:full_name, :id)
    study_program ? users.where(study_program_id: study_program.id) : users
  end

  def users_row(user)
    [ user.email, user.full_name, user.roles.map(&:code).sort.join("+"),
      user.study_program&.code.presence || user.study_program&.name, user.identifier_number, user.active_role&.name,
      user.work_unit, user.position, user.profession_category, user.specialization, user.phone,
      user.last_sign_in_at, user.created_at.to_date ]
  end

  def student_summary_count
    program_students.count
  end

  # Dihitung per kelompok (GROUP BY), bukan per mahasiswa, supaya rekap satu
  # prodi tetap beberapa query saja.
  def student_summary_rows
    students = program_students.includes(:study_program).order(:full_name, :id)
    ids = students.ids
    return if ids.empty?

    logs = within_dates(ActivityLog.where(user_id: ids), :activity_date)
    cases = within_dates(ClinicalCase.where(user_id: ids).where.not(status: "draft"), :case_date)
    activity_total = logs.group(:user_id).count
    activity_verified = logs.verified.group(:user_id).count
    cases_total = cases.group(:user_id).count
    cases_verified = cases.where(status: "verified").group(:user_id).count
    dops = evaluation_averages(DopsEvaluation, ids)
    mini_cex = evaluation_averages(MiniCexEvaluation, ids)
    assessments = assessment_percentages(ids)
    epa_items = EntrustmentDecision.current.where(student_id: ids).group(:student_id).distinct.count(:competency_item_id)
    final_status = FinalProject.where(student_id: ids).order(:created_at).pluck(:student_id, :status).to_h

    each_record(students) do |student|
      id = student.id
      yield [ student.full_name, student.email, student.identifier_number, student.study_program&.name, student.cohort_year,
              activity_total.fetch(id, 0), activity_verified.fetch(id, 0), cases_total.fetch(id, 0), cases_verified.fetch(id, 0),
              dops.dig(id, :count) || 0, dops.dig(id, :average), mini_cex.dig(id, :count) || 0, mini_cex.dig(id, :average),
              assessments.dig(id, :count) || 0, assessments.dig(id, :average), epa_items.fetch(id, 0),
              (FinalProject::STATUSES.fetch(final_status[id], final_status[id]) if final_status[id]) ]
    end
  end

  # Rata-rata dari rata-rata tiap evaluasi terkirim — hitungan yang sama
  # dengan Dashboard Analitik.
  def evaluation_averages(model, ids)
    rows = within_dates(model.submitted.where(student_id: ids), :evaluated_at).pluck(:student_id, :scores)
    rows.group_by(&:first).transform_values do |pairs|
      per_evaluation = pairs.map { |_, scores| average(scores.to_h.values.compact.map(&:to_i)) }
      { count: pairs.size, average: average(per_evaluation) }
    end
  end

  # Nilai wakil per event = percobaan tertinggi (AssessmentInstance.representative_for).
  def assessment_percentages(ids)
    scope = AssessmentInstance.scored.where(student_id: ids).where.not(score: nil)
    scope = scope.in_period(period) if period
    scope = within_dates(scope, :scored_at, time: true, include_period: false)
    rows = scope.pluck(:student_id, :assessment_event_id, :score, :max_score)
    rows.group_by(&:first).transform_values do |attempts|
      best = attempts.group_by(&:second).values.map do |per_event|
        per_event.filter_map { |*, score, max| (score.to_f / max.to_f * 100) unless max.to_f.zero? }.max
      end
      { count: best.compact.size, average: average(best) }
    end
  end

  # ── Perjalanan Belajar ──

  def activity_logs_scope
    logs = within_dates(within_program(ActivityLog.all, :user_id), :activity_date)
    logs.with_taxonomy.includes(:verified_by, :academic_period, :clinical_rotation, user: :study_program)
        .order(:activity_date, :started_at, :id)
  end

  def activity_logs_row(log)
    [ log.activity_date, log.started_at&.strftime("%H:%M"), log.ended_at&.strftime("%H:%M"), *student_cells(log.user),
      log.domain_label, log.academic_activity_subdomain&.name || log.activity_type, log.academic_activity_template&.name,
      log.category_label, log.title, log.location, log.delivery_mode_label, log.participant_count, log.academic_period&.name,
      log.clinical_rotation&.station_name, log.description, log.verified? ? "Terverifikasi" : "Belum diverifikasi",
      log.verified_by&.full_name, log.verified_at, log.evidence_url, log.document_url ]
  end

  # Draf belum diajukan ke pembimbing — di aplikasi hanya pemilik & admin
  # yang melihatnya (ClinicalCasePolicy#show?), di ekspor pun begitu.
  def clinical_cases_scope
    cases = within_dates(within_program(ClinicalCase.all, :user_id), :case_date)
    cases = cases.where.not(status: "draft") unless @admin
    cases.includes(:supervisor, :verified_by, user: :study_program).order(:case_date, :id)
  end

  def clinical_cases_row(kasus)
    [ kasus.id, kasus.case_date, *student_cells(kasus.user), kasus.status_label, kasus.chief_complaint, kasus.diagnosis,
      kasus.icd10_code, kasus.skdi_level, label_for(ClinicalContextOptions::CLINICAL_SETTINGS, kasus.clinical_setting),
      label_for(ClinicalContextOptions::CASE_COMPLEXITY, kasus.case_complexity), kasus.patient_age_group,
      kasus.patient_gender, kasus.patient_age, kasus.supervisor&.full_name, kasus.verified_by&.full_name,
      kasus.verified_at, (kasus.entrustment_level_label if kasus.entrustment_level.present?),
      kasus.recommend_remediation ]
  end

  def clinical_rotations_scope
    rotations = within_period(within_program(ClinicalRotation.all, :user_id), :academic_period_id)
    overlapping_dates(rotations)
      .includes(:academic_period, :preceptor, user: :study_program).order(:start_date, :id)
  end

  def clinical_rotations_row(rotation)
    [ *student_cells(rotation.user), rotation.station_name, rotation.institution_name, rotation.academic_period.name,
      rotation.start_date, rotation.end_date, rotation.status_label, rotation.preceptor&.full_name, rotation.preceptor&.email ]
  end

  def tutorial_enrollments_scope
    enrollments = within_period(within_program(TutorialEnrollment.all, :user_id), :academic_period_id)
    overlapping_dates(enrollments)
      .includes(:academic_period, :tutor, user: :study_program).order(:start_date, :block_name, :id)
  end

  def tutorial_enrollments_row(enrollment)
    [ *student_cells(enrollment.user), enrollment.block_name, enrollment.group_name, enrollment.academic_period.name,
      enrollment.start_date, enrollment.end_date, enrollment.tutor&.full_name, enrollment.tutor&.email, enrollment.status_label ]
  end

  def final_projects_scope
    within_program(FinalProject.all, :student_id)
      .includes(:supervisor, :final_project_milestones, :examiner_scores, student: :study_program).order(:created_at, :id)
  end

  def final_projects_row(project)
    milestones = project.final_project_milestones
    scores = project.examiner_scores.map(&:score)
    [ *student_cells(project.student), project.title, project.status_label, project.supervisor&.full_name,
      milestones.to_a.count { |m| m.completed_at.present? }, milestones.size, scores.size, average(scores), project.created_at.to_date ]
  end

  # ── Asesmen & Kompetensi ──

  def dops_evaluations_scope
    workplace_scope(DopsEvaluation)
  end

  def dops_evaluations_row(evaluation)
    [ *workplace_cells(evaluation, evaluation.procedure_name),
      *DopsEvaluation::DIMENSIONS.keys.map { |key| evaluation.score_for(key).presence&.to_i },
      evaluation.average_score, evaluation.overall_feedback ]
  end

  def mini_cex_evaluations_scope
    workplace_scope(MiniCexEvaluation)
  end

  def mini_cex_evaluations_row(evaluation)
    [ *workplace_cells(evaluation, evaluation.case_description),
      *MiniCexEvaluation::DIMENSIONS.keys.map { |key| evaluation.score_for(key).presence&.to_i },
      evaluation.average_score, (evaluation.global_rating_label if evaluation.global_rating.present?),
      evaluation.overall_feedback ]
  end

  def workplace_scope(model)
    within_dates(within_program(model.all, :student_id), :evaluated_at)
      .includes(:evaluator, :clinical_rotation, student: :study_program).order(:evaluated_at, :id)
  end

  def workplace_cells(evaluation, subject)
    [ evaluation.evaluated_at, *student_cells(evaluation.student), evaluation.evaluator.full_name,
      evaluation.clinical_rotation.station_name, subject, evaluation.status_label,
      label_for(ClinicalContextOptions::CLINICAL_SETTINGS, evaluation.clinical_setting),
      label_for(ClinicalContextOptions::CASE_COMPLEXITY, evaluation.case_complexity),
      label_for(ClinicalContextOptions::AGE_GROUPS, evaluation.patient_age_group),
      evaluation.observation_minutes, evaluation.feedback_minutes ]
  end

  def assessment_scores_scope
    instances = within_program(AssessmentInstance.joins(:assessment_event), :student_id)
    instances = instances.where(assessment_events: { academic_period_id: period.id }) if period
    within_dates(instances, :scored_at, time: true, include_period: false)
      .preload(:examiner, student: :study_program, assessment_event: %i[academic_period study_program])
      .order("assessment_events.exam_date", "assessment_events.id", :student_id, :attempt_number, :id)
  end

  def assessment_scores_row(instance)
    event = instance.assessment_event
    [ event.name, event.type_label, event.academic_period.name, event.study_program&.name, event.block_name, event.exam_date,
      *student_cells(instance.student), instance.attempt_number, instance.status_label, instance.score, instance.max_score,
      instance.percentage, instance.examiner&.full_name, instance.scored_at, label_for(ASSESSMENT_SOURCES, instance.source),
      instance.feedback_keep, instance.feedback_improve ]
  end

  def entrustment_decisions_scope
    within_dates(within_program(EntrustmentDecision.all, :student_id), "entrustment_decisions.created_at", time: true)
      .includes(:decided_by, competency_item: :competency_framework, student: :study_program).order(:created_at, :id)
  end

  def entrustment_decisions_row(decision)
    status = if decision.revoked? then "Dicabut"
    elsif decision.superseded_at then "Tergantikan"
    else "Berlaku"
    end
    [ decision.created_at, *student_cells(decision.student), decision.competency_item.competency_framework.name,
      decision.competency_item.title, decision.level, decision.level_label, decision.justification,
      decision.decided_by.full_name, decision.clinical_case_id, status ]
  end

  def evaluation_schedules_scope
    within_dates(within_program(EvaluationSchedule.all, :student_id), :scheduled_at, time: true)
      .includes(:evaluator, :clinical_rotation, student: :study_program).order(:scheduled_at, :id)
  end

  def evaluation_schedules_row(schedule)
    [ schedule.scheduled_at, schedule.kind_label, *student_cells(schedule.student), schedule.evaluator&.full_name,
      schedule.clinical_rotation&.station_name, schedule.topic, schedule.status_label, schedule.notes ]
  end

  # Mengikuti akses Form Builder (AssessmentFormSubmissionPolicy): pengelola
  # formulir membaca semua jawaban, tetapi responden formulir anonim hanya
  # terbuka bagi admin.
  def form_answers_scope
    answers = AssessmentFormAnswer.joins(:assessment_form_submission, :assessment_form_field)
    answers = answers.where(assessment_form_submissions: { assessment_form_template_id: form_template.id }) if form_template
    within_dates(answers, "assessment_form_submissions.submitted_at", time: true)
      .preload(:assessment_form_field, assessment_form_submission: %i[assessment_form_template respondent subject_user])
      .order("assessment_form_submissions.submitted_at", "assessment_form_submissions.id",
             "assessment_form_fields.position", "assessment_form_fields.id")
  end

  def form_answers_row(answer)
    submission = answer.assessment_form_submission
    field = answer.assessment_form_field
    visible = submission.respondent_visible_to?(@viewer)
    normalized = answer.numeric_value
    [ submission.assessment_form_template.name, submission.id, submission.submitted_at,
      visible ? submission.respondent.full_name : "Anonim", (submission.respondent.email if visible),
      submission.subject_user&.full_name || submission.subject_label, field.label, field.field_type_label,
      answer.value, (normalized * 100 if normalized) ]
  end

  # ── Master Data ──

  def diagnosis_definitions_scope = DiagnosisDefinition.order(:name, :id)
  def skill_definitions_scope = SkillDefinition.order(:name, :id)
  def medication_definitions_scope = MedicationDefinition.order(:name, :id)

  def diagnosis_definitions_row(record) = master_row(record)
  def skill_definitions_row(record) = master_row(record)
  def medication_definitions_row(record) = master_row(record)

  # Header master data = nama kolom model, jadi baris cukup dibaca per header.
  def master_row(record)
    dataset.headers.map { |column| record.public_send(column) }
  end

  # ── Format sel ──

  def cell(value)
    case value
    when nil then nil
    when true then "Ya"
    when false then "Tidak"
    when ActiveSupport::TimeWithZone, Time, DateTime then value.in_time_zone.strftime("%Y-%m-%d %H:%M")
    when Date then value.iso8601
    when Integer then value
    when Numeric then number(value)
    else
      text = value.to_s
      if excel_id? && text.match?(EXCEL_TEXT_NUMBER) then %(="#{text}")
      elsif text.match?(FORMULA_TRIGGER) then "'#{text}"
      else text
      end
    end
  end

  # 85.0 → "85", 85.25 → "85.25" (atau "85,25" untuk Excel Indonesia).
  def number(value)
    rounded = value.to_f.round(2)
    text = rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
    excel_id? ? text.tr(".", ",") : text
  end
end
