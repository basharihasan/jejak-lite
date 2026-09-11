require "test_helper"

class ExamScoresControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menampilkan skor milik sendiri per jenis ujian" do
    sign_in users(:siti)
    get exam_scores_path

    assert_response :success
    assert_match "78.0", response.body
  end
end
