require "test_helper"

# Konfigurasi → Kelola Ujian CBT (/admin/cbt_exams).
class Admin::CbtExamsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    @admin.update!(active_role: roles(:admin))
    @exam = assessment_events(:cbt_blok)
  end

  test "selain admin ditolak" do
    sign_in users(:siti)
    get admin_cbt_exams_path
    assert_redirected_to dashboard_path
  end

  test "daftar ujian CBT dengan jumlah peserta, tanpa event non-CBT" do
    sign_in @admin
    @exam.update!(external_code: "CBT-KARDIO-1", exam_purpose: "summative")
    get admin_cbt_exams_path
    assert_response :success
    assert_match @exam.name, response.body
    assert_match "CBT-KARDIO-1", response.body
    assert_match "#{@exam.assessment_instances.count} mahasiswa", response.body
    assert_match "Sumatif", response.body
    assert_no_match assessment_events(:soca_kardio).name, response.body

    get admin_cbt_exams_path(q: "tidak-ada-yang-cocok")
    assert_no_match @exam.name, response.body
  end

  test "sunting di tempat memakai Turbo Frame" do
    sign_in @admin
    get edit_admin_cbt_exam_path(@exam, field: "exam_date")
    assert_response :success
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@exam, :exam_date)} input[type=date]"
  end

  test "ganti tanggal ujian memindahkan tanggal nilai hasil impor" do
    sign_in @admin
    old_date = @exam.exam_date
    imported = AssessmentInstance.create!(assessment_event: @exam, student: users(:wati), max_score: 100, score: 70,
                                          status: "scored", source: "import", scored_at: old_date.in_time_zone, attempt_number: 9)
    new_date = old_date - 1

    patch admin_cbt_exam_path(@exam), params: { assessment_event: { exam_date: new_date.iso8601 } }
    assert_redirected_to admin_cbt_exams_path
    assert_equal new_date, @exam.reload.exam_date
    assert_equal new_date, imported.reload.scored_at.to_date

    patch admin_cbt_exam_path(@exam), params: { assessment_event: { name: "CBT Kardio (revisi)" } }
    assert_equal "CBT Kardio (revisi)", @exam.reload.name
  end

  test "ujian bernilai tidak dihapus; ujian kosong boleh dihapus" do
    sign_in @admin
    AssessmentInstance.create!(assessment_event: @exam, student: users(:wati), max_score: 100, score: 70, status: "scored", attempt_number: 9)
    delete admin_cbt_exam_path(@exam)
    assert_redirected_to admin_cbt_exams_path
    assert AssessmentEvent.exists?(@exam.id)

    empty = AssessmentEvent.create!(name: "CBT Kosong", assessment_type: "cbt", academic_period: @exam.academic_period, max_score: 100)
    delete admin_cbt_exam_path(empty)
    assert_not AssessmentEvent.exists?(empty.id)
  end
end
