# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  CATEGORIES = { "klinis" => "Klinis", "non_klinis" => "Non-Klinis" }.freeze
  DELIVERY_MODES = { "luring" => "Luring", "daring" => "Daring" }.freeze

  belongs_to :user

  has_many :activity_log_competency_tags, dependent: :destroy
  has_many :competency_items, through: :activity_log_competency_tags

  has_many_attached :evidence_files

  validates :title, :activity_date, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }

  scope :recent, -> { order(activity_date: :desc, created_at: :desc) }
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

  # Kode acak non-identifikasi (bukan nama/RM pasien) — cuma penanda supaya
  # mahasiswa bisa menautkan beberapa entri logbook ke "pasien yang sama"
  # tanpa menyimpan data pribadi apa pun. Dibuat sekali, dipakai ulang.
  def ensure_patient_code!
    return patient_code if patient_code.present?

    update!(patient_code: "P-#{SecureRandom.alphanumeric(8).upcase}")
    patient_code
  end
end
