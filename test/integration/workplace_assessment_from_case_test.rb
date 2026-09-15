require "test_helper"

# Paket Dasar Pilar B: Mini-CEX & DOPS diinisiasi mahasiswa dari kasus;
# penilai terisi dari preseptor rotasi yang mencakup tanggal kasus.
class WorkplaceAssessmentFromCaseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @kasus = clinical_cases(:submitted_case_siti)
    @kasus.update!(diagnosis: "Apendisitis akut", clinical_setting: "igd", patient_age_group: "Dewasa")
  end

  test "mahasiswa meminta Mini-CEX dari kasus; preseptor mengisi lalu mengirim ke mahasiswa" do
    sign_in users(:siti)
    get clinical_case_path(@kasus)
    assert_match "Minta Mini-CEX", response.body
    assert_match "Wati Preseptor", response.body

    assert_difference "MiniCexEvaluation.count", 1 do
      post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "mini_cex" }
    end
    evaluation = MiniCexEvaluation.order(:created_at).last
    assert_equal "requested", evaluation.status
    assert_equal users(:wati), evaluation.evaluator
    assert_equal @kasus, evaluation.clinical_case
    assert_equal "igd", evaluation.clinical_setting
    assert_equal "dewasa", evaluation.patient_age_group
    assert_match "Apendisitis akut", evaluation.case_description
    assert Notification.where(recipient: users(:wati)).where("title LIKE ?", "Permintaan Mini-CEX%").exists?

    sign_in users(:wati)
    get dashboard_path
    assert_match "Evaluasi Draf Belum Dikirim", response.body
    get mini_cex_evaluation_path(evaluation)
    assert_match "Isi Penilaian", response.body

    patch mini_cex_evaluation_path(evaluation), params: { mini_cex_evaluation: {
      status: "submitted", global_rating: "performed", case_description: evaluation.case_description,
      clinical_rotation_id: evaluation.clinical_rotation_id, student_id: users(:siti).id, evaluated_at: Date.current,
      scores: { komunikasi: 7, profesionalisme: 8, anamnesis: 6 }
    } }
    assert_equal "submitted", evaluation.reload.status
    assert_equal @kasus, evaluation.clinical_case
  end

  test "permintaan DOPS wajib menyebut prosedur" do
    sign_in users(:siti)
    assert_no_difference "DopsEvaluation.count" do
      post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "dops", procedure_name: " " }
    end

    assert_difference "DopsEvaluation.count", 1 do
      post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "dops", procedure_name: "Pemasangan infus" }
    end
    assert_equal "Pemasangan infus", DopsEvaluation.order(:created_at).last.procedure_name
  end

  test "mahasiswa membatalkan permintaan selama penilai belum mengisi" do
    sign_in users(:siti)
    post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "dops", procedure_name: "Hecting" }
    evaluation = DopsEvaluation.order(:created_at).last

    get dops_evaluation_path(evaluation)
    assert_match "Batalkan Permintaan", response.body

    assert_difference "DopsEvaluation.count", -1 do
      delete dops_evaluation_path(evaluation)
    end
    assert_redirected_to clinical_case_path(@kasus)
  end

  test "draf penilai tetap wajib mengisi dimensi wajib (N/A tidak boleh)" do
    sign_in users(:siti)
    post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "mini_cex" }
    evaluation = MiniCexEvaluation.order(:created_at).last

    evaluation.status = "draft"
    evaluation.global_rating = "performed"
    assert_not evaluation.valid?
    assert_match "wajib diisi", evaluation.errors.full_messages.to_sentence
  end

  test "kasus draf atau milik orang lain tidak bisa dipakai meminta asesmen" do
    sign_in users(:siti)
    draft = clinical_cases(:draft_case_siti)
    assert_no_difference "MiniCexEvaluation.count" do
      post initiate_workplace_assessment_clinical_case_path(draft), params: { kind: "mini_cex" }
    end

    sign_in users(:budi)
    assert_no_difference "MiniCexEvaluation.count" do
      post initiate_workplace_assessment_clinical_case_path(@kasus), params: { kind: "mini_cex" }
    end
  end
end
