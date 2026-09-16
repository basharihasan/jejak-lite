# frozen_string_literal: true

require "csv"
require "json"
require "digest"
require "fileutils"

# Ekspor seluruh isi jejak-lite sebagai satu PAKET MIGRASI menuju jejak.pro.
#
# Paket berisi dua lapis, sengaja keduanya:
#
#   data/      JSON per tabel — salinan LENGKAP apa adanya, termasuk kolom yang
#              belum punya rumah di jejak.pro. Jaring pengaman: apa pun yang
#              tidak terbawa importer masih ada dan bisa dipetakan belakangan
#              tanpa membuka basis data lama.
#
#   jejak_pro/ CSV yang dibaca `bin/rails jejak_lite:import` di jejak.pro
#              (JejakLiteBundleImporter). Nama & urutan kolom di sini adalah
#              KONTRAK dengan importer itu — ubah keduanya bersamaan.
#              pengguna.csv & rotasi_klinik.csv sekaligus berbentuk importer
#              CSV bawaan jejak.pro, jadi bisa juga diunggah lewat UI.
#
# Identitas pasien terenkripsi TIDAK ikut secara bawaan; harus diminta
# eksplisit (include_patient_identity: true) dan selalu dicatat di manifest.
class MigrationExporter
  # 1.1: logbook_kegiatan.csv mendapat kolom taksonomi & waktu di UJUNG
  # (aditif — importer 1.0 tetap bisa membaca, kolom baru diabaikan).
  FORMAT_VERSION = "1.1"

  # Tabel yang disalin utuh ke data/*.json.
  FULL_TABLES = %w[
    roles users user_roles study_programs academic_periods
    clinical_rotations tutorial_enrollments
    clinical_cases prescription_items patient_consents medication_definitions
    diagnosis_definitions skill_definitions logbook_case_targets
    academic_activity_domains academic_activity_subdomains academic_activity_templates
    activity_logs activity_log_competency_tags reflection_entries
    competency_frameworks competency_items competency_milestones
    assessment_blueprints assessment_blueprint_mappings
    assessment_events assessment_dimensions assessment_instances assessment_dimension_scores
    assessment_form_templates assessment_form_fields assessment_form_submissions assessment_form_answers
    entrustment_decisions evaluation_schedules
    dops_evaluations mini_cex_evaluations
    final_projects final_project_milestones examiner_scores
    exam_imports exam_scores
    learning_units assessment_mappings
    notifications app_settings break_glass_accesses case_verification_comments
    terminology_overrides
  ].freeze
  # Sengaja tidak ikut: device_push_tokens (kunci perangkat, tak berguna di
  # server lain) dan tabel Active Storage (berkasnya diekspor ke lampiran/).

  # Kolom yang tidak pernah ikut: rahasia autentikasi.
  SECRET_COLUMNS = %w[encrypted_password reset_password_token confirmation_token calendar_feed_token].freeze
  PATIENT_IDENTITY_COLUMNS = ClinicalCase::SENSITIVE_PATIENT_FIELDS.map(&:to_s).freeze
  # Rekaman yang lampirannya bisa memuat data pasien.
  PATIENT_RECORD_TYPES = %w[ClinicalCase PatientConsent].freeze

  # ── Kontrak kolom dengan JejakLiteBundleImporter (jejak.pro) ──
  USER_HEADERS = [ "Nama", "email", "NPM", "NIDN/NIDK", "HP", "Program Studi", "Status", "Tahun masuk", "Peran (jejak-lite)" ].freeze
  PERIOD_HEADERS = [ "Nama Periode (jejak-lite)", "Mulai", "Selesai", "Kode Periode jejak.pro" ].freeze
  ROTATION_HEADERS = [ "NPM", "Email Mahasiswa", "Blok Klinis", "Wahana", "Periode", "Mulai", "Selesai", "Status", "Tier", "Email Preseptor" ].freeze
  CASE_HEADERS = %w[
    id_jejak_lite email_mahasiswa tanggal status keluhan_utama diagnosis kode_icd10 level_skdi
    setting_klinik kompleksitas kelompok_usia jenis_kelamin usia pekerjaan anamnesis keadaan_umum
    pemeriksaan_fisik riwayat_keluarga tatalaksana resep poin_pembelajaran tingkat_entrustment
    email_verifikator waktu_verifikasi tanda_vital
  ].freeze
  CASE_IDENTITY_HEADERS = %w[nama_pasien no_rm tanggal_lahir_pasien telepon_pasien alamat_pasien].freeze
  # `domain`/`subdomain`/`bentuk_kegiatan` berisi NAMA — jejak.pro memakai
  # taksonomi bernama sama (AcademicActivityDomain dst.) dan mencocokkannya.
  ACTIVITY_HEADERS = %w[
    id_jejak_lite email_mahasiswa tanggal judul kategori mode deskripsi refleksi lokasi jumlah_peserta
    domain subdomain bentuk_kegiatan waktu_mulai waktu_selesai link_bukti link_dokumen
  ].freeze
  EMAIL_ALIAS_HEADERS = [ "Email jejak-lite", "Email jejak.pro" ].freeze
  COMPETENCY_HEADERS = [ "ID jejak-lite", "Kerangka", "Induk", "Nama", "Kode Kompetensi jejak.pro" ].freeze
  EVENT_HEADERS = [
    "ID jejak-lite", "Nama Event", "Tipe (kode)", "Tipe (label)", "Periode", "Prodi", "Blok", "Tanggal Ujian",
    "Nilai Maks", "Percobaan Berulang", "Jumlah Nilai", "Jumlah Dimensi", "Berkas Nilai",
    "ID Event jejak.pro", "ID Template jejak.pro"
  ].freeze
  SCORE_BASE_HEADERS = %w[email npm percobaan nilai nilai_maks nilai_persen].freeze

  attr_reader :dir, :summary

  def initialize(dir:, include_patient_identity: false)
    @dir = Pathname.new(dir)
    @include_patient_identity = include_patient_identity
    @summary = {}
    @checksums = {}
  end

  def call
    FileUtils.mkdir_p(@dir.join("data"))
    FileUtils.mkdir_p(@dir.join("jejak_pro", "nilai"))

    export_full_tables
    export_users_csv
    export_email_alias_template
    export_periods_csv
    export_rotations_csv
    export_clinical_cases_csv
    export_activity_logs_csv
    export_competencies_csv
    export_assessment_csvs
    export_competency_map_csv
    export_attachments
    write_manifest
    write_guide
    self
  end

  private

  # ── Lapis 1: salinan lengkap ──
  def export_full_tables
    FULL_TABLES.each do |table|
      next unless ActiveRecord::Base.connection.table_exists?(table)

      rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY id").to_a
      rows = rows.map { |row| scrub(table, row) }
      write_file("data/#{table}.json", JSON.pretty_generate(rows))
      @summary[table] = rows.size
    end
  end

  def scrub(table, row)
    row = row.except(*SECRET_COLUMNS)
    return row unless table == "clinical_cases"

    # Kolom terenkripsi dibaca lewat model supaya isinya terbawa sebagai teks
    # biasa; tanpa itu paket hanya berisi sandi yang tak bisa dibuka di server
    # lain (kunci enkripsinya berbeda).
    record = ClinicalCase.find_by(id: row["id"]) if @include_patient_identity
    PATIENT_IDENTITY_COLUMNS.each { |column| row[column] = record&.public_send(column) }
    row
  end

  # ── Lapis 2: CSV untuk jejak.pro ──

  # Kolom mengikuti CsvUserImporter jejak.pro; Status memakai label persis
  # dari CsvUserImporter::Constants::STATUS_MAP.
  def export_users_csv
    write_csv("jejak_pro/pengguna.csv", USER_HEADERS) do |csv|
      User.includes(:roles, :study_program).order(:email).find_each do |user|
        student = user.has_role?("mahasiswa")
        csv << [
          user.full_name, user.email,
          student ? user.identifier_number : nil,
          student ? nil : user.identifier_number,
          user.phone, user.study_program&.code.presence || user.study_program&.name,
          pro_status(user), user.cohort_year, user.roles.map(&:code).sort.join("+")
        ]
      end
    end
  end

  def pro_status(user)
    codes = user.roles.map(&:code)
    return "Mahasiswa" if codes.include?("mahasiswa")
    return "Dosen (preceptor, tutor, penguji)" if codes.include?("dosen") && codes.include?("preseptor")
    return "Dosen (preceptor, dokter di wahana pendidikan)" if codes.include?("preseptor")
    return "Dosen" if codes.intersect?(%w[dosen kaprodi])

    "Tenaga kependidikan"
  end

  # Sengaja kosong: diisi admin bila seseorang ternyata sudah punya akun
  # jejak.pro dengan email lain (importer melaporkan bentrok NPM/NIDN-nya).
  def export_email_alias_template
    write_csv("jejak_pro/padanan_email.csv", EMAIL_ALIAS_HEADERS) { |_csv| }
  end

  # Periode jejak-lite hanya punya nama & tanggal; jejak.pro memakai kode.
  # Kolom kode sengaja kosong: importer memadankan lewat nama semester & tahun
  # atau tumpang-tindih tanggal minimal separuh, kecuali admin mengisinya.
  def export_periods_csv
    write_csv("jejak_pro/periode.csv", PERIOD_HEADERS) do |csv|
      AcademicPeriod.order(:start_date).each do |period|
        csv << [ period.name, period.start_date, period.end_date, nil ]
      end
    end
  end

  # Kolom mengikuti ClinicalRotationImporter::TEMPLATE_HEADERS jejak.pro.
  # "Periode" berisi NAMA periode jejak-lite; importer paket menerjemahkannya.
  def export_rotations_csv
    write_csv("jejak_pro/rotasi_klinik.csv", ROTATION_HEADERS) do |csv|
      ClinicalRotation.includes(:user, :preceptor, :academic_period).order(:start_date).find_each do |rotation|
        csv << [
          rotation.user.identifier_number, rotation.user.email, rotation.station_name, rotation.institution_name,
          rotation.academic_period.name, rotation.start_date, rotation.end_date,
          rotation.status == "selesai" ? "selesai" : "aktif", nil, rotation.preceptor&.email
        ]
      end
    end
  end

  def export_clinical_cases_csv
    headers = CASE_HEADERS + (@include_patient_identity ? CASE_IDENTITY_HEADERS : [])
    write_csv("jejak_pro/kasus_klinis.csv", headers) do |csv|
      ClinicalCase.includes(:user, :verified_by, :prescription_items).order(:case_date, :id).find_each do |kasus|
        row = [
          kasus.id, kasus.user.email, kasus.case_date, kasus.status, kasus.chief_complaint, kasus.diagnosis,
          kasus.icd10_code, kasus.skdi_level, kasus.clinical_setting, kasus.case_complexity, kasus.patient_age_group,
          kasus.patient_gender, kasus.patient_age, kasus.patient_occupation, kasus.anamnesis, kasus.general_condition,
          kasus.physical_examination, kasus.family_history, kasus.management,
          kasus.prescription_items.map { |item| [ item.prescription_line, item.signa_line ].compact.join(" ") }.join("\n"),
          kasus.learning_points, kasus.entrustment_level, kasus.verified_by&.email, kasus.verified_at&.iso8601,
          kasus.vital_signs.presence&.to_json
        ]
        if @include_patient_identity
          row += [ kasus.patient_name, kasus.patient_medical_record_number, kasus.patient_birth_date,
                   kasus.patient_phone, kasus.patient_address ]
        end
        csv << row
      end
    end
  end

  def export_activity_logs_csv
    write_csv("jejak_pro/logbook_kegiatan.csv", ACTIVITY_HEADERS) do |csv|
      ActivityLog.includes(:user).with_taxonomy.order(:activity_date, :id).find_each do |log|
        csv << [ log.id, log.user.email, log.activity_date, log.title, log.category, log.delivery_mode,
                 log.description, log.reflection, log.location, log.participant_count,
                 log.academic_activity_domain&.name, log.academic_activity_subdomain&.name,
                 log.academic_activity_template&.name, log.started_at&.iso8601, log.ended_at&.iso8601,
                 log.evidence_url, log.document_url ]
      end
    end
  end

  # Ranah kompetensi jejak-lite tidak berkode; importer mencocokkan NAMA ke
  # CompetencyItem jejak.pro, atau memakai kode yang diisi admin di sini.
  def export_competencies_csv
    write_csv("jejak_pro/kompetensi.csv", COMPETENCY_HEADERS) do |csv|
      CompetencyItem.includes(:competency_framework, :parent).order(:competency_framework_id, :position, :id).each do |item|
        csv << [ item.id, item.competency_framework.name, item.parent&.title, item.title, nil ]
      end
    end
  end

  # Satu berkas nilai per event: nilai asli, nilai dalam persen (jejak.pro
  # menyimpan 0–100), mentah per dimensi (untuk dibaca manusia), dan persen
  # per ranah kompetensi ("kompetensi:<id>") hasil gabungan dimensi ujian &
  # pertanyaan rubrik yang dipetakan — sama dengan hitungan Peta Kompetensi.
  def export_assessment_csvs
    index_rows = []
    AssessmentEvent.includes(:academic_period, :study_program, :assessment_form_template).order(:id).each do |event|
      dimensions = event.assessment_dimensions.ordered.to_a
      competency_ids = competency_ids_for(event, dimensions)
      filename = "jejak_pro/nilai/#{event.id}-#{event.name.parameterize.presence || 'event'}.csv"
      headers = SCORE_BASE_HEADERS + dimensions.map { |d| "dimensi:#{d.label}" } + competency_ids.map { |id| "kompetensi:#{id}" }

      instances = event.assessment_instances
                       .where(status: "scored").where.not(score: nil)
                       .includes(:student, assessment_dimension_scores: :assessment_dimension)
                       .order(:student_id, :attempt_number).to_a

      write_csv(filename, headers) do |csv|
        instances.each do |instance|
          by_dimension = instance.assessment_dimension_scores.index_by(&:assessment_dimension_id)
          percentages = competency_percentages(instance)
          csv << [ instance.student.email, instance.student.identifier_number, instance.attempt_number,
                   instance.score, instance.max_score, percent_of(instance.score, instance.max_score) ] +
                 dimensions.map { |d| by_dimension[d.id]&.score } +
                 competency_ids.map { |id| percentages[id] }
        end
      end

      multiple = event.allow_multiple_attempts || instances.any? { |i| i.attempt_number > 1 }
      index_rows << [ event.id, event.name, event.assessment_type, event.type_label, event.academic_period.name,
                      event.study_program&.name, event.block_name, event.exam_date, event.max_score,
                      multiple ? "ya" : "tidak", instances.size, dimensions.size, filename, nil, nil ]
    end

    write_csv("jejak_pro/daftar_event_asesmen.csv", EVENT_HEADERS) do |csv|
      index_rows.each { |row| csv << row }
    end
  end

  def competency_ids_for(event, dimensions)
    ids = dimensions.filter_map(&:competency_item_id)
    if event.assessment_form_template
      ids += event.assessment_form_template.assessment_form_fields.select(&:scorable?).filter_map(&:competency_item_id)
    end
    ids.uniq.sort
  end

  def competency_percentages(instance)
    contributions = instance.assessment_dimension_scores.filter_map do |row|
      dimension = row.assessment_dimension
      percentage = row.percentage
      next if dimension.competency_item_id.nil? || percentage.nil?

      [ dimension.competency_item_id, percentage.to_f, dimension.weight.to_f ]
    end

    submission = AssessmentFormSubmission.find_by(id: instance.assessment_form_submission_id)
    submission&.assessment_form_answers&.includes(:assessment_form_field)&.each do |answer|
      field = answer.assessment_form_field
      next if field.nil? || field.competency_item_id.nil? || !field.scorable?

      normalized = answer.numeric_value
      contributions << [ field.competency_item_id, normalized * 100, field.weight.to_f ] unless normalized.nil?
    end

    contributions.group_by(&:first).filter_map do |item_id, rows|
      weight = rows.sum { |r| r[2] }
      [ item_id, (rows.sum { |r| r[1] * r[2] } / weight).round(2) ] unless weight.zero?
    end.to_h
  end

  def percent_of(score, max)
    return nil if score.nil? || max.to_f.zero?

    (score.to_f / max.to_f * 100).round(2)
  end

  # Daftar acuan untuk manusia — bukan dibaca importer.
  def export_competency_map_csv
    write_csv("jejak_pro/pemetaan_kompetensi.csv",
              [ "Sumber", "Induk", "Nama", "ID Ranah jejak-lite", "Ranah Kompetensi", "Bobot", "Skala Maks" ]) do |csv|
      AssessmentDimension.includes(:assessment_event, :competency_item).order(:assessment_event_id, :id).each do |dimension|
        csv << [ "Dimensi ujian", dimension.assessment_event.name, dimension.label,
                 dimension.competency_item_id, dimension.competency_item&.title, dimension.weight, dimension.max_score ]
      end
      AssessmentFormField.includes(:assessment_form_template, :competency_item).order(:assessment_form_template_id, :id).each do |field|
        next unless field.scorable?

        csv << [ "Pertanyaan rubrik", field.assessment_form_template.name, field.label,
                 field.competency_item_id, field.competency_item&.title, field.weight, field.max_score ]
      end
    end
  end

  def export_attachments
    write_csv("jejak_pro/lampiran.csv", [ "Jenis Rekaman", "ID Rekaman", "Nama Lampiran", "Nama Berkas", "Berkas di Paket", "Catatan" ]) do |csv|
      ActiveStorage::Attachment.includes(:blob).order(:id).each do |attachment|
        blob = attachment.blob
        base = [ attachment.record_type, attachment.record_id, attachment.name, blob.filename.to_s ]

        if PATIENT_RECORD_TYPES.include?(attachment.record_type) && !@include_patient_identity
          csv << base + [ nil, "dilewati: dapat memuat data pasien" ]
          next
        end

        relative = File.join("lampiran", attachment.record_type.underscore, attachment.record_id.to_s,
                             "#{attachment.id}-#{blob.filename.sanitized}")
        begin
          write_file(relative, blob.download, binary: true)
          csv << base + [ relative, nil ]
        rescue ActiveStorage::FileNotFoundError
          csv << base + [ nil, "berkas tidak ditemukan di penyimpanan" ]
        end
      end
    end
  end

  def write_csv(relative_path, headers)
    path = @dir.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    CSV.open(path, "w", write_headers: true, headers: headers) { |csv| yield csv }
    @summary[relative_path] = CSV.read(path, headers: true).size
    @checksums[relative_path] = Digest::SHA256.file(path).hexdigest
  end

  def write_file(relative_path, content, binary: false)
    path = @dir.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    binary ? path.binwrite(content) : path.write(content)
    @checksums[relative_path] = Digest::SHA256.file(path).hexdigest
  end

  def write_manifest
    @dir.join("manifest.json").write(JSON.pretty_generate(
      format_version: FORMAT_VERSION,
      generated_at: Time.current.iso8601,
      source: { app: "jejak-lite", rails_env: Rails.env,
                schema_version: ActiveRecord::Base.connection_pool.migration_context.current_version.to_s },
      patient_identity_included: @include_patient_identity,
      counts: @summary,
      checksums: @checksums
    ))
  end

  def write_guide
    identity_note = if @include_patient_identity
      "Paket ini **MEMUAT identitas pasien** (nama, No. RM, tanggal lahir, telepon, alamat) sebagai teks biasa. " \
      "Perlakukan seperti rekam medis: kirim terenkripsi, jangan lewat surel biasa, hapus setelah migrasi selesai."
    else
      "Paket ini **tidak memuat identitas pasien** (kolomnya dikosongkan, lampiran kasus dilewati). " \
      "Bila memang perlu ikut dipindahkan, ekspor ulang dengan `INCLUDE_PATIENT_IDENTITY=true`."
    end

    @dir.join("PANDUAN_MIGRASI.md").write(<<~MD)
      # Paket Migrasi jejak-lite → jejak.pro

      Dibuat #{Time.current.strftime('%d-%m-%Y %H:%M')} · format #{FORMAT_VERSION}

      #{identity_note}

      ## Langkah di jejak.pro

      1. Salin folder paket ini ke server jejak.pro.
      2. **Uji coba dulu (tidak menyimpan apa pun):**

         ```
         bin/rails jejak_lite:import DIR=/lokasi/paket ORG=<slug-organisasi> TEMPLATE_ID=<id-template-alur>
         ```

         Laporan menampilkan jumlah per langkah dibandingkan jumlah di paket, beserta setiap baris yang bermasalah.
      3. Bereskan yang dilaporkan — biasanya dengan mengisi kolom kosong di CSV paket ini:
         - `jejak_pro/periode.csv` → **Kode Periode jejak.pro** bila periode tak ditemukan otomatis;
         - `jejak_pro/kompetensi.csv` → **Kode Kompetensi jejak.pro** bila nama ranah tak sama persis;
         - `jejak_pro/daftar_event_asesmen.csv` → **ID Event jejak.pro** (menempel ke event yang sudah ada) atau **ID Template jejak.pro**;
         - `jejak_pro/padanan_email.csv` → tautkan akun jejak-lite ke akun jejak.pro yang sudah ada (orang yang sama, email berbeda).

         Daftar kode yang tersedia: `bin/rails jejak_lite:referensi ORG=<slug-organisasi>`.
      4. Ulangi uji coba sampai bersih, lalu simpan sungguhan dengan menambahkan `COMMIT=1`.
         Penyimpanan bersifat semua-atau-tidak-sama-sekali: bila masih ada galat, tidak ada yang tersimpan.
      5. Impor boleh diulang — baris yang sudah masuk dikenali dan tidak digandakan.

      ## Isi paket

      - `manifest.json` — versi format, jumlah baris & checksum SHA-256 setiap berkas.
      - `data/*.json` — salinan lengkap setiap tabel (jaring pengaman; tidak semua kolom punya padanan).
      - `jejak_pro/` — berkas yang dibaca importer; `pengguna.csv` dan `rotasi_klinik.csv` juga bisa diunggah lewat menu impor biasa.
      - `lampiran/` — berkas unggahan, diindeks di `jejak_pro/lampiran.csv` (dipasang manual bila diperlukan).

      ## Setelah impor

      - Semua pengguna baru mendapat email konfirmasi dan harus memakai **Lupa Kata Sandi** — kata sandi tidak pernah ikut diekspor.
      - Peran admin/kaprodi ditetapkan ulang lewat Peran & Akses (kolom "Peran (jejak-lite)" di `pengguna.csv` sebagai acuan).
    MD
  end
end
