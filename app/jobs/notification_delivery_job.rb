# frozen_string_literal: true

# Mengirim Web Push untuk satu notifikasi ke semua perangkat pengguna yang
# terdaftar. Kalau VAPID belum dikonfigurasi (ENV kosong), job berhenti diam
# tanpa error — notifikasi in-app tetap tersimpan dan tampil di dropdown,
# cuma tidak ada push ke perangkat.
class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    return unless vapid_configured?

    notification = Notification.find_by(id: notification_id)
    return if notification.nil?

    notification.recipient.device_push_tokens.find_each do |token|
      deliver(token, notification)
    end
  end

  private

  def vapid_configured?
    ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
  end

  def deliver(token, notification)
    WebPush.payload_send(
      message: JSON.generate(title: notification.title, body: notification.message.to_s),
      endpoint: token.endpoint,
      p256dh: token.p256dh_key,
      auth: token.auth_key,
      vapid: {
        subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@jejaklite.test"),
        public_key: ENV["VAPID_PUBLIC_KEY"],
        private_key: ENV["VAPID_PRIVATE_KEY"]
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    token.destroy
  end
end
