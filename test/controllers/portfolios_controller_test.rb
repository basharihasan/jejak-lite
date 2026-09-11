require "test_helper"

class PortfolioControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:budi) }

  test "menolak akses tanpa login" do
    sign_out users(:budi)
    get portfolio_path
    assert_redirected_to new_user_session_path
  end

  test "menampilkan ringkasan hanya dari kegiatan milik sendiri" do
    get portfolio_path

    assert_response :success
    assert_match "2", response.body # total kegiatan budi
  end

  test "export mengunduh CSV berisi kegiatan milik sendiri" do
    get export_portfolio_path

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match activity_logs(:jaga_igd).title, response.body
    assert_no_match activity_logs(:kegiatan_siti).title, response.body
  end
end
