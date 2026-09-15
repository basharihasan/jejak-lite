require "test_helper"

class BrandControllerTest < ActionDispatch::IntegrationTest
  test "halaman brand terbuka tanpa login" do
    get brand_path
    assert_response :success
    assert_match "JEJAK Essential", response.body
  end
end
