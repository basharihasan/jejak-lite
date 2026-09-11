require "test_helper"

class AssessmentFormTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "pengguna biasa hanya melihat formulir aktif, tidak bisa membuat" do
    sign_in users(:siti)
    get assessment_form_templates_path
    assert_response :success
    assert_match assessment_form_templates(:tutor_evaluation).name, response.body

    get new_assessment_form_template_path
    assert_response :redirect
  end

  test "admin bisa membuat formulir baru" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "AssessmentFormTemplate.count", 1 do
      post assessment_form_templates_path, params: {
        assessment_form_template: { name: "Evaluasi Blok", description: "Evaluasi blok oleh mahasiswa", is_active: true }
      }
    end
  end
end
