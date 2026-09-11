require "test_helper"

class FinalProjectMilestoneTest < ActiveSupport::TestCase
  test "overdue? true kalau lewat target dan belum selesai" do
    overdue = FinalProjectMilestone.new(final_project: final_projects(:skripsi_siti), title: "Telat", target_date: 1.day.ago.to_date)
    assert overdue.overdue?
  end

  test "toggle_completed! membalik status selesai" do
    milestone = final_project_milestones(:sidang_akhir)
    assert_not milestone.completed?

    milestone.toggle_completed!
    assert milestone.completed?

    milestone.toggle_completed!
    assert_not milestone.completed?
  end
end
