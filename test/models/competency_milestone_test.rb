require "test_helper"

class CompetencyMilestoneTest < ActiveSupport::TestCase
  test "expected_score harus 1-9" do
    milestone = CompetencyMilestone.new(competency_item: competency_items(:domain_komunikasi), academic_period: academic_periods(:current_period), expected_score: 10)
    assert_not milestone.valid?
  end

  test "satu domain hanya boleh punya satu target per periode" do
    duplikat = CompetencyMilestone.new(
      competency_item: competency_items(:domain_klinis), academic_period: academic_periods(:current_period), expected_score: 5
    )
    assert_not duplikat.valid?
  end
end
