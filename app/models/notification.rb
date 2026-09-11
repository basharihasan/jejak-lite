# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :active, -> { where(archived_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :deliver_push_later

  def read?
    read_at.present?
  end

  def mark_as_read!
    update(read_at: Time.current) unless read?
  end

  def archive!
    update(archived_at: Time.current)
  end

  # Titik masuk tunggal untuk membuat notifikasi — dipakai fitur lain
  # (verifikasi logbook, dsb.) begitu ada, supaya delivery push selalu ikut
  # terpicu tanpa perlu diingat manual di setiap pemanggil.
  def self.notify!(recipient:, title:, message: nil, sender: nil, notifiable: nil, notification_type: nil)
    create!(
      recipient: recipient,
      sender: sender,
      notifiable: notifiable,
      title: title,
      message: message,
      notification_type: notification_type
    )
  end

  private

  def deliver_push_later
    NotificationDeliveryJob.perform_later(id)
  end
end
