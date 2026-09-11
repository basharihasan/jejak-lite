require "test_helper"

class AssessmentBlueprintsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak boleh mengakses" do
    sign_in users(:siti)
    get assessment_blueprints_path
    assert_response :redirect
  end

  test "admin bisa melihat daftar blueprint" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get assessment_blueprints_path
    assert_response :success
    assert_match assessment_blueprints(:osce_blueprint).name, response.body
  end

  test "admin bisa membuat blueprint dari baris teks Ranah: Bobot" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "AssessmentBlueprint.count", 1 do
      post assessment_blueprints_path, params: {
        assessment_blueprint: {
          name: "Blueprint Baru",
          description: "Contoh",
          competency_mapping_text: "Kardiovaskular: 60\nRespirasi: 40",
          learning_outcomes_text: "Mampu mendiagnosis nyeri dada"
        }
      }
    end

    blueprint = AssessmentBlueprint.find_by(name: "Blueprint Baru")
    assert_equal 100.0, blueprint.total_weight
    assert_equal [ "Mampu mendiagnosis nyeri dada" ], blueprint.learning_outcomes
  end
end
