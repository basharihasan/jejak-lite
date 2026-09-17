require "test_helper"

class SignInLinksEmailDeliveryTest < ActionDispatch::IntegrationTest
  teardown { Rails.configuration.x.email_delivery_enabled = nil }

  test "tautan berbasis email tampil bila server email ada" do
    get new_user_session_path
    assert_match "Lupa kata sandi?", response.body
    assert_match "Belum menerima instruksi konfirmasi?", response.body
  end

  test "tautan berbasis email disembunyikan bila server email belum diatur" do
    Rails.configuration.x.email_delivery_enabled = false
    get new_user_session_path
    assert_response :success
    assert_no_match "Lupa kata sandi?", response.body
    assert_no_match "Belum menerima instruksi konfirmasi?", response.body
  end
end
