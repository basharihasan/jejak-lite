require "test_helper"

class AssessmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get assessments_path
    assert_redirected_to new_user_session_path
  end

  test "mahasiswa hanya melihat evaluasi miliknya sendiri" do
    sign_in users(:siti)
    get assessments_path

    assert_response :success
    assert_match dops_evaluations(:dops_siti_infus).procedure_name, response.body
    assert_match mini_cex_evaluations(:minicex_siti_demam).case_description, response.body
  end

  test "tombol buat evaluasi hanya muncul untuk instruktur" do
    sign_in users(:siti)
    get assessments_path
    assert_no_match "new_dops_evaluation", response.body

    sign_in users(:budi)
    get assessments_path
    assert_match new_dops_evaluation_path, response.body
  end

  test "draf milik evaluator sendiri muncul di panel Menunggu Diselesaikan" do
    draft = DopsEvaluation.create!(
      student: users(:siti), evaluator: users(:budi), clinical_rotation: clinical_rotations(:ongoing_rotation_siti),
      procedure_name: "Draf Tes", evaluated_at: Date.current, status: "draft",
      scores: { komunikasi: 7, profesionalisme: 7, penilaian_global: 7 }
    )

    sign_in users(:budi)
    get assessments_path
    assert_match "Menunggu Diselesaikan", response.body
    assert_match draft.procedure_name, response.body
  end
end
