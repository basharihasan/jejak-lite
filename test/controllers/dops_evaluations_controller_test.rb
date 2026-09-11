require "test_helper"

class DopsEvaluationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak bisa membuat evaluasi" do
    sign_in users(:siti)
    get new_dops_evaluation_path
    assert_response :redirect
  end

  test "mahasiswa bisa melihat evaluasi miliknya sendiri" do
    sign_in users(:siti)
    get dops_evaluation_path(dops_evaluations(:dops_siti_infus))
    assert_response :success
  end

  test "mahasiswa tidak bisa melihat evaluasi milik mahasiswa lain" do
    other = User.create!(full_name: "Lain", email: "dopslain@example.com", password: "password123", confirmed_at: Time.current)
    other.roles << roles(:mahasiswa)

    sign_in other
    get dops_evaluation_path(dops_evaluations(:dops_siti_infus))
    assert_response :redirect
  end

  test "dosen membuat evaluasi DOPS baru" do
    sign_in users(:budi)

    assert_difference "DopsEvaluation.count", 1 do
      post dops_evaluations_path, params: {
        dops_evaluation: {
          student_id: users(:siti).id, clinical_rotation_id: clinical_rotations(:ongoing_rotation_siti).id,
          procedure_name: "Kateter Urin", evaluated_at: Date.current,
          scores: { komunikasi: 7, profesionalisme: 8, penilaian_global: 7 }
        }
      }
    end

    dops = DopsEvaluation.order(:id).last
    assert_equal users(:budi), dops.evaluator
    assert_redirected_to dops_evaluation_path(dops)
  end

  test "mahasiswa lain (bukan penilai) tidak bisa menyunting evaluasi" do
    dosen_lain = User.create!(full_name: "Dosen Lain", email: "dosenlain@example.com", password: "password123", confirmed_at: Time.current)
    dosen_lain.roles << roles(:dosen)

    sign_in dosen_lain
    get edit_dops_evaluation_path(dops_evaluations(:dops_siti_infus))
    assert_response :redirect
  end

  test "evaluator bisa menyimpan draf lalu mengirimkannya" do
    sign_in users(:budi)

    post dops_evaluations_path, params: {
      dops_evaluation: {
        student_id: users(:siti).id, clinical_rotation_id: clinical_rotations(:ongoing_rotation_siti).id,
        procedure_name: "Jahit Luka", evaluated_at: Date.current, status: "draft",
        scores: { komunikasi: 7, profesionalisme: 8, penilaian_global: 7 }
      }
    }
    dops = DopsEvaluation.order(:id).last
    assert dops.draft?

    assert_difference "Notification.count", 1 do
      patch submit_dops_evaluation_path(dops)
    end
    assert dops.reload.submitted?
  end
end
