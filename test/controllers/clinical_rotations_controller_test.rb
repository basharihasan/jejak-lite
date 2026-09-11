require "test_helper"

class ClinicalRotationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get clinical_rotations_path
    assert_redirected_to new_user_session_path
  end

  test "mahasiswa hanya melihat rotasinya sendiri" do
    sign_in users(:siti)
    get clinical_rotations_path

    assert_response :success
    assert_match clinical_rotations(:ongoing_rotation_siti).station_name, response.body
  end

  test "dosen melihat rotasi yang dia bimbing" do
    sign_in users(:budi)
    get clinical_rotations_path

    assert_response :success
    assert_match clinical_rotations(:ongoing_rotation_siti).station_name, response.body
    assert_no_match clinical_rotations(:upcoming_rotation_siti).station_name, response.body
  end

  test "mahasiswa tidak bisa membuat rotasi" do
    sign_in users(:siti)
    get new_clinical_rotation_path
    assert_response :redirect
  end

  test "admin bisa membuat rotasi baru" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "ClinicalRotation.count", 1 do
      post clinical_rotations_path, params: {
        clinical_rotation: {
          user_id: users(:siti).id, academic_period_id: academic_periods(:current_period).id,
          station_name: "Obstetri Ginekologi", start_date: Date.current, end_date: 10.days.from_now.to_date
        }
      }
    end

    assert_redirected_to clinical_rotations_path
  end
end
