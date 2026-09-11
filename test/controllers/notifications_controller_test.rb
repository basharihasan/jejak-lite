require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:budi) }

  test "menolak akses tanpa login" do
    sign_out users(:budi)
    get notifications_path
    assert_redirected_to new_user_session_path
  end

  test "index hanya menampilkan notifikasi aktif milik pengguna sendiri" do
    get notifications_path

    assert_response :success
    assert_match notifications(:unread_for_budi).title, response.body
    assert_no_match notifications(:archived_for_budi).title, response.body
  end

  test "tidak bisa menandai notifikasi milik orang lain" do
    other_notification = Notification.create!(recipient: users(:siti), title: "Punya Siti")

    patch mark_as_read_notification_path(other_notification)

    assert_response :not_found
    assert_not other_notification.reload.read?
  end

  test "mark_as_read menandai satu notifikasi via turbo_stream" do
    notification = notifications(:unread_for_budi)

    patch mark_as_read_notification_path(notification), as: :turbo_stream

    assert_response :success
    assert notification.reload.read?
  end

  test "archive menghapus notifikasi dari daftar aktif" do
    notification = notifications(:unread_for_budi)

    patch archive_notification_path(notification), as: :turbo_stream

    assert_response :success
    assert notification.reload.archived_at.present?
  end

  test "mark_all_read menandai semua notifikasi aktif" do
    patch mark_all_read_notifications_path, as: :turbo_stream

    assert_response :success
    assert_equal 0, users(:budi).notifications.unread.active.count
  end
end
