require "test_helper"

class ExamImportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak bisa mengakses impor" do
    sign_in users(:siti)
    get exam_imports_path
    assert_response :redirect
  end

  test "admin bisa mengimpor CSV skor" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    csv = Rack::Test::UploadedFile.new(
      StringIO.new("email,score,exam_date\n#{users(:siti).email},80,#{Date.current}\n"),
      "text/csv", original_filename: "skor.csv"
    )

    assert_difference "ExamScore.count", 1 do
      post exam_imports_path, params: { kind: "cbt", name: "CBT Uji", file: csv }
    end

    assert_response :success
  end
end
