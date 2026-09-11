require "test_helper"

class ExamScoreTest < ActiveSupport::TestCase
  test "percentage menghitung skor terhadap max_score" do
    assert_equal 78.0, exam_scores(:skor_siti_cbt1).percentage
  end

  test "kind didelegasikan dari exam_import" do
    assert_equal "cbt", exam_scores(:skor_siti_cbt1).kind
  end

  test "for_kind menyaring lewat exam_import" do
    assert_includes ExamScore.for_kind("cbt"), exam_scores(:skor_siti_cbt1)
    assert_not_includes ExamScore.for_kind("osce"), exam_scores(:skor_siti_cbt1)
  end
end
