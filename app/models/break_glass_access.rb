# frozen_string_literal: true

# Jejak audit "Break Glass" — pembukaan identitas pasien yang disamarkan
# Privacy Mode, dengan alasan tertulis dan masa berlaku singkat. Baris tidak
# pernah dihapus: ini catatan kepatuhan, bukan sesi.
class BreakGlassAccess < ApplicationRecord
  DURATION = 30.minutes
  MIN_REASON_LENGTH = 10

  belongs_to :user
  belongs_to :clinical_case

  validates :reason, presence: true, length: { minimum: MIN_REASON_LENGTH, message: "minimal #{MIN_REASON_LENGTH} karakter" }
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  def self.grant!(user:, clinical_case:, reason:, ip_address: nil)
    create!(user: user, clinical_case: clinical_case, reason: reason.to_s.strip,
            expires_at: DURATION.from_now, ip_address: ip_address)
  end

  def self.active_for(user, clinical_case)
    active.where(user: user, clinical_case: clinical_case).order(expires_at: :desc).first
  end

  def active?
    expires_at > Time.current
  end
end
