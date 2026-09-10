require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:budi) }

  test "menolak akses tanpa login" do
    sign_out users(:budi)
    get search_path
    assert_redirected_to new_user_session_path
  end

  test "kosongkan hasil kalau query kosong" do
    get search_path
    assert_response :success
    assert_no_match users(:siti).email, response.body
  end

  test "menemukan pengguna lewat nama atau email" do
    get search_path, params: { q: "siti" }
    assert_response :success
    assert_match users(:siti).full_name, response.body
  end
end
