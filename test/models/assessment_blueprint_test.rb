require "test_helper"

class AssessmentBlueprintTest < ActiveSupport::TestCase
  test "valid ketika bobot mapping kompetensi berjumlah 100" do
    blueprint = AssessmentBlueprint.create!(name: "Blueprint Baru")
    blueprint.assessment_blueprint_mappings.create!(competency_item: competency_items(:domain_klinis), weight: 60)
    blueprint.assessment_blueprint_mappings.create!(competency_item: competency_items(:domain_komunikasi), weight: 40)

    assert blueprint.valid?
  end

  test "tidak valid ketika bobot mapping kompetensi tidak berjumlah 100" do
    blueprint = AssessmentBlueprint.create!(name: "Blueprint Baru")
    blueprint.assessment_blueprint_mappings.create!(competency_item: competency_items(:domain_klinis), weight: 60)
    blueprint.assessment_blueprint_mappings.create!(competency_item: competency_items(:domain_komunikasi), weight: 30)

    assert_not blueprint.valid?
    assert blueprint.errors[:base].any? { |m| m.include?("90.0%") }
  end

  test "boleh tanpa peta kompetensi sama sekali" do
    blueprint = AssessmentBlueprint.new(name: "Blueprint Draf")
    assert blueprint.valid?
  end

  test "total_weight menjumlahkan seluruh bobot mapping" do
    blueprint = assessment_blueprints(:osce_blueprint)
    assert_equal 100.0, blueprint.total_weight
  end

  test "weight_by_competency_item mengembalikan hash CompetencyItem ke bobot" do
    blueprint = assessment_blueprints(:osce_blueprint)
    weights = blueprint.weight_by_competency_item

    assert_equal 60.0, weights[competency_items(:domain_klinis)]
    assert_equal 40.0, weights[competency_items(:domain_komunikasi)]
  end
end
