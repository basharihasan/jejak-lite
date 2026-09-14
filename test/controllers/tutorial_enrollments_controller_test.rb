require "test_helper"

class TutorialEnrollmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get tutorial_enrollments_path
    assert_redirected_to new_user_session_path
  end

  test "mahasiswa melihat enrolmennya sendiri tanpa tombol kelola" do
    sign_in users(:siti)
    get tutorial_enrollments_path

    assert_response :success
    assert_match "Sistem Kardiovaskular", response.body
    assert_no_match "Tambah Enrolment", response.body
  end

  test "dosen tutor melihat mahasiswa yang dia ampu" do
    sign_in users(:budi)
    get tutorial_enrollments_path

    assert_response :success
    assert_match users(:siti).full_name, response.body
  end

  test "preseptor tanpa tutee tidak melihat enrolmen orang lain" do
    sign_in users(:wati)
    get tutorial_enrollments_path

    assert_response :success
    assert_no_match "Sistem Kardiovaskular", response.body
  end

  test "mahasiswa tidak bisa membuat enrolmen" do
    sign_in users(:siti)
    get new_tutorial_enrollment_path
    assert_response :redirect
  end

  test "admin membuat, menonaktifkan, dan menghapus enrolmen" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "TutorialEnrollment.count", 1 do
      post tutorial_enrollments_path, params: {
        tutorial_enrollment: {
          user_id: users(:siti).id, tutor_id: users(:budi).id,
          academic_period_id: academic_periods(:current_period).id,
          block_name: "Sistem Respirasi", group_name: "Kelompok 1", active: true
        }
      }
    end
    assert_redirected_to tutorial_enrollments_path

    enrollment = TutorialEnrollment.find_by!(block_name: "Sistem Respirasi")
    patch toggle_active_tutorial_enrollment_path(enrollment)
    assert_equal false, enrollment.reload.active

    assert_difference "TutorialEnrollment.count", -1 do
      delete tutorial_enrollment_path(enrollment)
    end
  end

  test "blok yang sama tidak boleh didaftarkan dua kali pada periode yang sama" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_no_difference "TutorialEnrollment.count" do
      post tutorial_enrollments_path, params: {
        tutorial_enrollment: {
          user_id: users(:siti).id, academic_period_id: academic_periods(:current_period).id,
          block_name: "Sistem Kardiovaskular"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "tutee aktif tampil sebagai mahasiswa bimbingan tutor di Dashboard Analitik" do
    sign_in users(:budi)
    get analytics_path

    assert_response :success
    assert_match users(:siti).full_name, css_select("main").text
  end
end
