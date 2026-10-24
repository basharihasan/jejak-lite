require "test_helper"

class AssessmentFormTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa dan dosen tidak bisa membuka Form Builder maupun mengisi formulir" do
    template = assessment_form_templates(:tutor_evaluation)

    [ users(:siti), users(:budi) ].each do |user|
      sign_in user

      get assessment_form_templates_path
      assert_redirected_to root_path
      get assessment_form_template_path(template)
      assert_redirected_to root_path
      get new_assessment_form_template_path
      assert_redirected_to root_path
      get new_assessment_form_template_assessment_form_submission_path(template)
      assert_redirected_to root_path
    end
  end

  test "menu Form Builder hanya tampil bagi kaprodi dan admin" do
    sign_in users(:siti)
    get root_path
    assert_select "a[href=?]", assessment_form_templates_path, count: 0

    sign_in users(:dedi)
    get root_path
    assert_select "a[href=?]", assessment_form_templates_path, minimum: 1
  end

  test "kaprodi mengelola formulir seperti admin" do
    sign_in users(:dedi)

    get assessment_form_templates_path
    assert_response :success
    assert_match assessment_form_templates(:tutor_evaluation).name, response.body
    assert_match "+ Formulir Baru", response.body

    assert_difference "AssessmentFormTemplate.count", 1 do
      post assessment_form_templates_path, params: {
        assessment_form_template: { name: "Evaluasi Blok", description: "Evaluasi blok oleh mahasiswa", is_active: true }
      }
    end
    template = AssessmentFormTemplate.order(:id).last

    assert_difference "template.assessment_form_fields.count", 1 do
      post assessment_form_template_assessment_form_fields_path(template), params: {
        assessment_form_field: { label: "Kejelasan tujuan blok", field_type: "rating", required: true }
      }
    end

    get assessment_form_template_path(template)
    assert_response :success
    assert_match "Kejelasan tujuan blok", response.body
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
