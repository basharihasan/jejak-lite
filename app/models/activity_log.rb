# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  CATEGORIES = { "klinis" => "Klinis", "non_klinis" => "Non-Klinis" }.freeze
  DELIVERY_MODES = { "luring" => "Luring", "daring" => "Daring" }.freeze

  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  has_many :activity_log_competency_tags, dependent: :destroy
  has_many :competency_items, through: :activity_log_competency_tags

  has_many_attached :evidence_files

  validates :title, :activity_date, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }

  scope :recent, -> { order(activity_date: :desc, created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }
  scope :awaiting_verification, -> { where(verified_at: nil) }
  scope :verified, -> { where.not(verified_at: nil) }
  scope :klinis, -> { where(category: "klinis") }
  scope :non_klinis, -> { where(category: "non_klinis") }
  scope :in_month, ->(date) { where(activity_date: date.beginning_of_month..date.end_of_month) }
  scope :tagged_with, ->(competency_item_id) { joins(:activity_log_competency_tags).where(activity_log_competency_tags: { competency_item_id: competency_item_id }) }

  def delivery_mode_label
    DELIVERY_MODES.fetch(delivery_mode, delivery_mode)
  end

  def category_label
    CATEGORIES.fetch(category, category)
  end

  def verified?
    verified_at.present?
  end

  def verify!(by:)
    update!(verified_at: Time.current, verified_by: by)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kegiatan terverifikasi", message: title
    )
  end

  # Kode acak non-identifikasi (bukan nama/RM pasien) — cuma penanda supaya
  # mahasiswa bisa menautkan beberapa entri logbook ke "pasien yang sama"
  # tanpa menyimpan data pribadi apa pun. Dibuat sekali, dipakai ulang.
  def ensure_patient_code!
    return patient_code if patient_code.present?

    update!(patient_code: "P-#{SecureRandom.alphanumeric(8).upcase}")
    patient_code
  end
end
