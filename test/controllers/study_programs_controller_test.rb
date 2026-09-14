require "test_helper"

class StudyProgramsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "bukan admin ditolak" do
    sign_in users(:dedi) # kaprodi
    get study_programs_path
    assert_response :redirect
  end

  test "admin melihat daftar prodi berkode dan dapat menyunting" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get study_programs_path
    assert_response :success
    assert_match "pssk", response.body
    assert_match "pspd", response.body

    patch study_program_path(study_programs(:sarjana_kedokteran)), params: { study_program: { name: "Sarjana Kedokteran (S1)", code: "pssk", level: "sarjana" } }
    assert_redirected_to study_programs_path
    assert_equal "Sarjana Kedokteran (S1)", study_programs(:sarjana_kedokteran).reload.name
  end

  test "kode prodi harus unik dan berformat huruf kecil" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    post study_programs_path, params: { study_program: { name: "Prodi Baru", code: "PSSK", level: "sarjana" } }
    assert_response :unprocessable_entity

    assert_difference "StudyProgram.count", 1 do
      post study_programs_path, params: { study_program: { name: "Profesi Ners", code: "profesi-ners", level: "profesi" } }
    end
  end
end
