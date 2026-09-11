require "test_helper"

class AssessmentBlueprintTest < ActiveSupport::TestCase
  test "valid ketika bobot kompetensi berjumlah 100" do
    blueprint = AssessmentBlueprint.new(name: "Blueprint Baru", competency_mapping: { "A" => 60, "B" => 40 })
    assert blueprint.valid?
  end

  test "tidak valid ketika bobot kompetensi tidak berjumlah 100" do
    blueprint = AssessmentBlueprint.new(name: "Blueprint Baru", competency_mapping: { "A" => 60, "B" => 30 })
    assert_not blueprint.valid?
    assert blueprint.errors[:competency_mapping].any? { |m| m.include?("90.0%") }
  end

  test "boleh tanpa peta kompetensi sama sekali" do
    blueprint = AssessmentBlueprint.new(name: "Blueprint Draf")
    assert blueprint.valid?
  end

  test "total_weight menjumlahkan seluruh bobot" do
    blueprint = assessment_blueprints(:osce_blueprint)
    assert_equal 100.0, blueprint.total_weight
  end
end
