# frozen_string_literal: true

# Role — peran akun.
# Cukup kode + nama tampilan; tidak ada category/domain_permissions/capability
# karena JEJAK Essential tidak butuh IAM enterprise, hanya "akun ini boleh lihat
# menu apa" lewat has_role?/active_role.
class Role < ApplicationRecord
  # Peran yang boleh dipilih sendiri di form Daftar publik — hanya mahasiswa.
  # Dosen/preseptor membuka kasus klinis seluruh mahasiswa (termasuk Break
  # Glass identitas pasien) dan kaprodi/admin seluruh prodi/instalasi, jadi
  # semuanya hanya diberikan admin lewat Konfigurasi → Pengguna (sunting atau
  # impor CSV). Kalau dosen bisa diklaim sendiri, siapa pun di internet bisa
  # membaca data pasien.
  SELF_REGISTRABLE_CODES = %w[mahasiswa].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  def self.self_registrable?(code)
    SELF_REGISTRABLE_CODES.include?(code.to_s)
  end
end
