# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  belongs_to :active_role, class_name: "Role", optional: true

  has_one_attached :avatar

  has_many :notifications, foreign_key: :recipient_id, inverse_of: :recipient, dependent: :destroy
  has_many :device_push_tokens, dependent: :destroy

  validates :full_name, presence: true

  # Akun yang masuk lewat Google tidak pernah mengisi form registrasi biasa,
  # jadi password acak + confirmed_at langsung diisi di sini (bukan lewat
  # alur konfirmasi email Devise) — konsisten dengan pola Google-login yang
  # "sudah terverifikasi oleh Google".
  def self.from_google_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email ||= auth.info.email
    user.full_name = auth.info.name if user.full_name.blank?

    if user.new_record?
      user.password = Devise.friendly_token[0, 20]
      user.confirmed_at = Time.current
    end

    user.save
    user
  end

  def has_role?(code)
    roles.exists?(code: code.to_s)
  end

  # Menukar peran aktif — dipakai fitur "Ganti Peran". Menolak pindah ke
  # peran yang tidak dimiliki, supaya Dashboard tidak pernah bercabang ke
  # peran yang sebenarnya tidak disandang user ini.
  def switch_active_role!(role_code)
    role = roles.find_by(code: role_code.to_s)
    return false unless role

    update(active_role: role)
  end
end
