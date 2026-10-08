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

  test "formulir tambah mapping di halaman detail mengirim parameter yang diterima controller" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    blueprint = AssessmentBlueprint.create!(name: "Blueprint Kosong")

    get assessment_blueprint_path(blueprint)
    assert_select "form[action=?]", assessment_blueprint_assessment_blueprint_mappings_path(blueprint) do
      assert_select "select[name=?]", "assessment_blueprint_mapping[competency_item_id]"
      assert_select "input[name=?]", "assessment_blueprint_mapping[weight]"
    end
  end

  test "blueprint yang dipakai unit pembelajaran bisa dihapus; unitnya tetap ada" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin
    blueprint = AssessmentBlueprint.create!(name: "Blueprint Lepas")
    unit = LearningUnit.create!(name: "Blok Uji", study_program: study_programs(:sarjana_kedokteran), assessment_blueprint: blueprint)

    assert_difference "AssessmentBlueprint.count", -1 do
      delete assessment_blueprint_path(blueprint)
    end
    assert_nil unit.reload.assessment_blueprint_id
  end
end
