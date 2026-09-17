require "test_helper"

class UserEmailDeliveryTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  teardown { Rails.configuration.x.email_delivery_enabled = nil }

  def build_user(email)
    User.new(full_name: "Pendaftar", email: email, password: "rahasia-kuat-1")
  end

  test "dengan server email, akun baru wajib konfirmasi dan email dikirim" do
    user = build_user("baru.smtp@example.com")
    assert_emails(1) { user.save! }
    assert_not user.active_for_authentication?
  end

  test "tanpa server email, akun baru bisa langsung masuk dan tak ada email dikirim" do
    Rails.configuration.x.email_delivery_enabled = false
    user = build_user("baru.tanpa.smtp@example.com")
    assert_no_emails { user.save! }
    assert user.active_for_authentication?
  end

  test "tanpa server email, akun lama yang belum terkonfirmasi tidak lagi terkunci" do
    user = users(:siti)
    user.update_columns(confirmed_at: nil)
    assert_not user.reload.active_for_authentication?

    Rails.configuration.x.email_delivery_enabled = false
    assert user.active_for_authentication?
  end

  test "tanpa server email, ganti email langsung berlaku tanpa menunggu konfirmasi" do
    Rails.configuration.x.email_delivery_enabled = false
    user = users(:siti)
    assert_no_emails { user.update!(email: "siti.baru@example.com") }
    assert_equal "siti.baru@example.com", user.reload.email
  end
end
