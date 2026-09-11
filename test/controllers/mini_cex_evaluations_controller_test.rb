require "test_helper"

class MiniCexEvaluationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak bisa membuat evaluasi" do
    sign_in users(:siti)
    get new_mini_cex_evaluation_path
    assert_response :redirect
  end

  test "dosen membuat evaluasi Mini-CEX baru" do
    sign_in users(:budi)

    assert_difference "MiniCexEvaluation.count", 1 do
      post mini_cex_evaluations_path, params: {
        mini_cex_evaluation: {
          student_id: users(:siti).id, clinical_rotation_id: clinical_rotations(:ongoing_rotation_siti).id,
          case_description: "Konsultasi hipertensi", evaluated_at: Date.current,
          scores: { komunikasi: 7, profesionalisme: 8 }, global_rating: "performed"
        }
      }
    end

    assert_redirected_to mini_cex_evaluation_path(MiniCexEvaluation.order(:id).last)
  end
end
