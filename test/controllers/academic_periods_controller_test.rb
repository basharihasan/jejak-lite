require "test_helper"

class AcademicPeriodsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak boleh mengakses" do
    sign_in users(:siti)
    get academic_periods_path
    assert_response :redirect
  end

  test "admin bisa mengelola periode" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get academic_periods_path
    assert_response :success
    assert_match academic_periods(:current_period).name, response.body
  end
end
