require "test_helper"
require "csv"

class Admin::ExportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @admin.update!(active_role: roles(:admin))
    @kaprodi = users(:dedi) # kaprodi Sarjana Kedokteran
    @pspd = study_programs(:profesi_dokter)
  end

  def create_student(email, program:)
    user = User.create!(full_name: email.split("@").first.capitalize, email: email, password: "password123",
                        confirmed_at: Time.current, study_program: program)
    user.roles << roles(:mahasiswa)
    user
  end

  def csv_rows(col_sep: ",")
    CSV.parse(response.body.dup.force_encoding("UTF-8").delete_prefix("﻿"), headers: true, col_sep: col_sep)
  end

  test "selain admin dan kaprodi ditolak" do
    sign_in users(:wati)
    get admin_exports_path
    assert_redirected_to dashboard_path

    get admin_export_path("students", format: :csv)
    assert_redirected_to dashboard_path
    assert_equal 0, DataExportLog.count
  end

  test "kaprodi tanpa prodi diarahkan ke admin" do
    @kaprodi.update!(study_program: nil)
    sign_in @kaprodi
    get admin_export_path("students", format: :csv)

    assert_redirected_to dashboard_path
    assert_match "belum terhubung ke Program Studi", flash[:alert]
  end

  test "admin melihat semua dataset, pilihan prodi, dan menu di Konfigurasi" do
    sign_in @admin
    get admin_exports_path

    assert_response :success
    assert_select "aside#sidebar a[href=?]", admin_exports_path, text: "Ekspor Data (CSV)", count: 1
    DataExport::DATASETS.each_key { |key| assert_select "#dataset-#{key}" }
    assert_select "select[name=study_program_id]"
    assert_select "#dataset-students [data-row-count]", text: /1 baris/ # siti
  end

  test "kaprodi tidak melihat dataset khusus admin dan prodinya terkunci" do
    sign_in @kaprodi
    get admin_exports_path

    assert_response :success
    assert_select "aside#sidebar a[href=?]", admin_exports_path, count: 1
    assert_select "#dataset-students"
    assert_select "#dataset-users", count: 0
    assert_select "#dataset-diagnosis_definitions", count: 0
    assert_select "select[name=study_program_id]", count: 0
    assert_match "Sarjana Kedokteran", response.body
  end

  test "ekspor kaprodi dikunci ke prodinya walau prodi lain diminta" do
    create_student("pspd1@example.com", program: @pspd)
    sign_in @kaprodi
    get admin_export_path("students", format: :csv, study_program_id: @pspd.id)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "jejak-data-mahasiswa-pssk-", response.headers["Content-Disposition"]
    assert_equal [ "siti@example.com" ], csv_rows.map { |row| row["Email"] }
  end

  test "kaprodi tidak dapat mengunduh dataset khusus admin" do
    sign_in @kaprodi
    get admin_export_path("users", format: :csv)

    assert_redirected_to admin_exports_path
    assert_equal 0, DataExportLog.count
  end

  test "setiap unduhan tercatat di riwayat ekspor" do
    sign_in @admin
    assert_difference -> { DataExportLog.count }, 1 do
      get admin_export_path("activity_logs", format: :csv, study_program_id: study_programs(:sarjana_kedokteran).id)
    end

    titles = csv_rows.map { |row| row["Topik"] }
    assert_equal [ "Tutorial Skenario Nyeri Dada", "Kunjungan Rumah" ], titles # milik siti, urut tanggal
    log = DataExportLog.last
    assert_equal [ @admin, "activity_logs", 2 ], [ log.user, log.dataset, log.row_count ]
    assert_equal "Sarjana Kedokteran", log.filters["prodi"]

    get admin_exports_path
    assert_select "td", text: "Logbook Kegiatan"
  end

  test "kasus klinis tidak memuat identitas pasien dan draf hanya untuk admin" do
    submitted = clinical_cases(:submitted_case_siti)
    submitted.update!(patient_name: "Ny. Rahasia Sekali", patient_medical_record_number: "RM-998877")
    draft = clinical_cases(:draft_case_siti)

    sign_in @kaprodi
    get admin_export_path("clinical_cases", format: :csv)
    assert_equal [ submitted.id.to_s ], csv_rows.map { |row| row["ID Kasus"] }
    assert_no_match "Rahasia", response.body
    assert_no_match "RM-998877", response.body

    sign_in @admin
    get admin_export_path("clinical_cases", format: :csv)
    assert_includes csv_rows.map { |row| row["ID Kasus"] }, draft.id.to_s
    assert_no_match "Rahasia", response.body
  end

  test "teks berawalan tanda rumus dinetralkan" do
    payload = '=HYPERLINK("http://jahat.example","klik")'
    activity_logs(:kegiatan_siti).update_columns(title: payload)
    sign_in @admin
    get admin_export_path("activity_logs", format: :csv)

    assert_includes csv_rows.map { |row| row["Topik"] }, "'#{payload}"
  end

  test "format Excel Indonesia memakai titik koma, koma desimal, dan NPM sebagai teks" do
    users(:siti).update!(identifier_number: "0130110240012")
    sign_in @admin
    get admin_export_path("dops_evaluations", format: :csv, csv_format: "excel_id")

    row = csv_rows(col_sep: ";").first
    assert_equal '="0130110240012"', row["NPM / NIM"]
    assert_equal "6,9", row["Rata-rata Skor"]
    assert_equal "Pemasangan Infus", row["Prosedur"]
  end

  test "tanggal Dari sesudah Sampai ditolak" do
    sign_in @admin
    get admin_export_path("activity_logs", format: :csv, from: "2026-10-10", to: "2026-10-01")

    assert_redirected_to %r{/admin/exports\?}
    assert_match "harus sebelum", flash[:alert]
    assert_equal 0, DataExportLog.count
  end

  test "responden formulir anonim hanya terbuka bagi admin" do
    template = assessment_form_templates(:tutor_evaluation)
    submission = template.assessment_form_submissions.build(respondent: users(:siti), subject_user: users(:budi),
                                                            submitted_at: Time.current)
    submission.assessment_form_answers.build(assessment_form_field: assessment_form_fields(:kejelasan_materi), value: "4")
    submission.save!

    sign_in @kaprodi
    get admin_export_path("form_answers", format: :csv, form_template_id: template.id)
    row = csv_rows.first
    assert_equal [ "Anonim", nil ], [ row["Responden"], row["Email Responden"] ]
    assert_equal [ "Budi Dosen", "4", "80" ], [ row["Subjek"], row["Jawaban"], row["Skor (%)"] ]
    assert_no_match "siti@example.com", response.body

    sign_in @admin
    get admin_export_path("form_answers", format: :csv, form_template_id: template.id)
    assert_equal "Siti Mahasiswa", csv_rows.first["Responden"]
  end
end
