require "test_helper"

# Konfigurasi → Impor CSV CBT & OSCE (/admin/glide_syncs/csv_import): unggah
# berkas .csv berformat ekspor Glide, ringkasan, riwayat, rollback, templat.
class Admin::GlideSyncsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  OSCE_CSV = "rowID,emailYangDiuji,emailPenguji,tanggalEntry,station,kasus,Anamnesis,PemeriksaanFisik,globalRating,halBaik,perluDitingkatkan\n" \
             "o1,siti@example.com,wati@example.com,%<at>s,1,Demam dengue,3,2,Good,Anamnesis runtut,Edukasi pasien\n".freeze

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @admin.update!(active_role: roles(:admin))
    @date = 2.days.ago.to_date
  end

  def upload(content, name = "data.csv")
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: name)
  end

  def cbt_csv
    "email,exam_code,exam_title,exam_type,total_score,held_at,Komunikasi efektif\n" \
      "siti@example.com,CBT-HTTP-1,Ujian CBT HTTP,summative,77,#{@date.iso8601},80\n"
  end

  def osce_csv = format(OSCE_CSV, at: "#{@date.iso8601}T02:00:00.000Z")

  test "selain admin ditolak" do
    sign_in users(:wati)
    get csv_import_admin_glide_syncs_path
    assert_redirected_to dashboard_path

    post csv_import_admin_glide_syncs_path, params: { importer_type: "cbt", csv_file: upload(cbt_csv) }
    assert_redirected_to dashboard_path
    assert_equal 0, GlideImport.count
  end

  test "halaman unggah menawarkan CBT Exam Results dan OSCE" do
    sign_in @admin
    get csv_import_admin_glide_syncs_path
    assert_response :success
    assert_match "CBT Exam Results", response.body
    assert_match "data_cbt_exams_glide.csv", response.body
    assert_match "Penilaian OSCE (8 dimensi klinis)", response.body
    assert_select "input[type=radio][name=importer_type][value=cbt]"
    assert_select "input[type=radio][name=importer_type][value=osce]"
    assert_select "input[type=file][name=csv_file]"
  end

  test "unggah CSV CBT → ringkasan → nilai masuk" do
    sign_in @admin
    post csv_import_admin_glide_syncs_path, params: { importer_type: "cbt", csv_file: upload(cbt_csv, "data_cbt_exams_glide.csv"),
                                                      study_program_id: study_programs(:sarjana_kedokteran).id }
    import = GlideImport.last
    assert_redirected_to admin_glide_sync_path(import)
    assert_equal @admin, import.imported_by
    assert_equal "data_cbt_exams_glide.csv", import.filename

    follow_redirect!
    assert_response :success
    assert_match "Ujian CBT HTTP", response.body
    assert_select "[data-testid=import-summary]"

    event = AssessmentEvent.find_by!(external_code: "CBT-HTTP-1")
    assert_equal study_programs(:sarjana_kedokteran), event.study_program
    assert_equal 77.0, event.assessment_instances.find_by!(student: users(:siti)).score.to_f
  end

  test "unggah CSV OSCE dengan event tujuan pilihan admin" do
    sign_in @admin
    target = AssessmentEvent.create!(name: "OSCE Blok", assessment_type: "osce", academic_period: academic_periods(:current_period),
                                     max_score: 100, status: "published")
    post csv_import_admin_glide_syncs_path, params: { importer_type: "osce", csv_file: upload(osce_csv), target_event_id: target.id }
    assert_redirected_to admin_glide_sync_path(GlideImport.last)
    assert_equal 1, target.osce_station_scores.count
  end

  test "berkas kosong, bukan .csv, atau tipe tak dikenal ditolak sebelum diproses" do
    sign_in @admin
    post csv_import_admin_glide_syncs_path, params: { importer_type: "cbt" }
    assert_redirected_to csv_import_admin_glide_syncs_path
    post csv_import_admin_glide_syncs_path, params: { importer_type: "cbt", csv_file: upload(cbt_csv, "nilai.xlsx") }
    assert_redirected_to csv_import_admin_glide_syncs_path
    post csv_import_admin_glide_syncs_path, params: { importer_type: "dops", csv_file: upload(cbt_csv) }
    assert_redirected_to csv_import_admin_glide_syncs_path
    assert_equal 0, GlideImport.count
  end

  test "riwayat impor dan rollback lewat HTTP" do
    sign_in @admin
    post csv_import_admin_glide_syncs_path, params: { importer_type: "osce", csv_file: upload(osce_csv) }
    import = GlideImport.last
    assert_equal 1, OsceStationScore.count

    get admin_glide_syncs_path
    assert_response :success
    assert_match "##{import.id}", response.body

    get admin_glide_sync_path(import)
    assert_select "form[action='#{rollback_admin_glide_sync_path(import)}']"

    post rollback_admin_glide_sync_path(import)
    assert_redirected_to admin_glide_sync_path(import)
    assert_equal 0, OsceStationScore.count
    assert_equal "rolled_back", import.reload.status

    post rollback_admin_glide_sync_path(import)
    assert_match "tidak dapat di-rollback", flash[:alert]
  end

  test "templat CSV memakai header persis ekspor Glide" do
    sign_in @admin
    get template_admin_glide_syncs_path(type: "osce", format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    header = response.body.delete_prefix("﻿").lines.first
    assert_match "emailYangDiuji", header
    assert_match "PerilakuProfesional", header

    get template_admin_glide_syncs_path(type: "cbt", format: :csv)
    assert_match "exam_code", response.body
  end

  test "tab Station OSCE di halaman event menampilkan rincian per station" do
    sign_in @admin
    post csv_import_admin_glide_syncs_path, params: { importer_type: "osce", csv_file: upload(osce_csv) }
    event = AssessmentEvent.find_by!(external_code: "OSCE-GLIDE-#{@date.iso8601}")

    get admin_assessment_event_path(event, tab: "station")
    assert_response :success
    assert_match "Station OSCE (1)", response.body
    assert_match "Station 1 — Demam dengue", response.body
    assert_match "Rata-rata dimensi klinis", response.body
  end
end
