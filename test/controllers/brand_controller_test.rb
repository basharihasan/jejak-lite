require "test_helper"

class BrandControllerTest < ActionDispatch::IntegrationTest
  test "halaman brand terbuka tanpa login" do
    get brand_path
    assert_response :success
    assert_match "Jejak Lite", response.body
  end
end
