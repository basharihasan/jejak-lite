require "test_helper"

class FinalProjectTest < ActiveSupport::TestCase
  test "average_examiner_score menghitung rata-rata skor" do
    project = final_projects(:skripsi_siti)
    assert_equal 82.5, project.average_examiner_score
  end

  test "milestones_completed_count hanya menghitung yang selesai" do
    assert_equal 1, final_projects(:skripsi_siti).milestones_completed_count
  end
end
