require "test_helper"

class PanduanControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get panduan_path
    assert_redirected_to new_user_session_path
  end

  test "merender markdown panduan sebagai HTML" do
    sign_in users(:budi)
    get panduan_path

    assert_response :success
    assert_select "h1", "Panduan Pengguna Jejak Lite"
  end
end
