require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "unread mencakup hanya yang belum dibaca" do
    assert_includes Notification.unread, notifications(:unread_for_budi)
    assert_not_includes Notification.unread, notifications(:read_for_budi)
  end

  test "active mengecualikan yang terarsip" do
    assert_not_includes Notification.active, notifications(:archived_for_budi)
  end

  test "mark_as_read! mengisi read_at sekali saja" do
    notification = notifications(:unread_for_budi)
    assert_nil notification.read_at

    notification.mark_as_read!
    assert notification.read?
  end

  test "notify! membuat notifikasi dan menjadwalkan pengiriman push" do
    assert_enqueued_with(job: NotificationDeliveryJob) do
      assert_difference "Notification.count", 1 do
        Notification.notify!(recipient: users(:siti), title: "Halo")
      end
    end
  end
end
