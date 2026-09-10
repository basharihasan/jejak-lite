require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "menu langkah berikutnya menyesuaikan peran aktif" do
    sign_in users(:budi) # active_role: dosen

    get dashboard_path

    assert_response :success
    assert_match "Lengkapi profil", response.body
    assert_no_match "Cari pengguna", response.body # kartu khusus admin
  end

  test "peran admin melihat kartu cari pengguna" do
    admin_user = users(:budi)
    admin_user.roles << roles(:admin)
    admin_user.update!(active_role: roles(:admin))
    sign_in admin_user

    get dashboard_path

    assert_match "Cari pengguna", response.body
  end
end
