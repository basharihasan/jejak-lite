require "test_helper"

class CompetencyFrameworksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa boleh melihat daftar dan detail (read-only)" do
    sign_in users(:siti)

    get competency_frameworks_path
    assert_response :success

    get competency_framework_path(competency_frameworks(:skdi_ringkas))
    assert_response :success
    assert_match competency_items(:domain_klinis).title, response.body
  end

  test "mahasiswa tidak boleh membuat peta kompetensi baru" do
    sign_in users(:siti)
    get new_competency_framework_path
    assert_response :redirect
  end

  test "admin bisa membuat peta kompetensi" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    assert_difference "CompetencyFramework.count", 1 do
      post competency_frameworks_path, params: { competency_framework: { name: "Peta Baru" } }
    end
  end
end
