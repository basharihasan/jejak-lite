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

  test "admin bisa membuat blueprint dan menambah mapping kompetensi" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "AssessmentBlueprint.count", 1 do
      post assessment_blueprints_path, params: {
        assessment_blueprint: {
          name: "Blueprint Baru",
          description: "Contoh",
          learning_outcomes_text: "Mampu mendiagnosis nyeri dada"
        }
      }
    end

    blueprint = AssessmentBlueprint.find_by(name: "Blueprint Baru")
    assert_equal [ "Mampu mendiagnosis nyeri dada" ], blueprint.learning_outcomes

    assert_difference "AssessmentBlueprintMapping.count", 1 do
      post assessment_blueprint_assessment_blueprint_mappings_path(blueprint), params: {
        assessment_blueprint_mapping: { competency_item_id: competency_items(:domain_klinis).id, weight: 100 }
      }
    end
    assert_equal 100.0, blueprint.reload.total_weight
  end

  test "mahasiswa tidak bisa menambah mapping" do
    sign_in users(:siti)

    assert_no_difference "AssessmentBlueprintMapping.count" do
      post assessment_blueprint_assessment_blueprint_mappings_path(assessment_blueprints(:osce_blueprint)), params: {
        assessment_blueprint_mapping: { competency_item_id: competency_items(:domain_komunikasi).id, weight: 10 }
      }
    end
  end
end
