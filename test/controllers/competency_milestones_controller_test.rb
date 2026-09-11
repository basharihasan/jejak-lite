require "test_helper"

class CompetencyMilestonesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admin bisa menambah target milestone baru" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    periode_baru = AcademicPeriod.create!(name: "Periode Baru", start_date: 1.month.from_now, end_date: 6.months.from_now)

    assert_difference "CompetencyMilestone.count", 1 do
      post competency_item_competency_milestones_path(competency_items(:domain_komunikasi)),
        params: { competency_milestone: { academic_period_id: periode_baru.id, expected_score: 6 } }
    end
  end

  test "mahasiswa tidak bisa menambah target milestone" do
    sign_in users(:siti)

    assert_no_difference "CompetencyMilestone.count" do
      post competency_item_competency_milestones_path(competency_items(:domain_komunikasi)),
        params: { competency_milestone: { academic_period_id: academic_periods(:current_period).id, expected_score: 6 } }
    end
  end

  test "admin bisa menghapus target milestone" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    milestone = competency_milestones(:klinis_target_current_period)
    assert_difference "CompetencyMilestone.count", -1 do
      delete competency_item_competency_milestone_path(milestone.competency_item, milestone)
    end
  end
end
