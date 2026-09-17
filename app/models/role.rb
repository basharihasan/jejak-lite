# frozen_string_literal: true

# Role — pengganti ringan FunctionalRole/UserPersona/Capability JEJAK.
# Cukup kode + nama tampilan; tidak ada category/domain_permissions/capability
# karena jejak-lite tidak butuh IAM enterprise, hanya "akun ini boleh lihat
# menu apa" lewat has_role?/active_role.
class Role < ApplicationRecord
  # Peran yang boleh dipilih sendiri di form Daftar publik. Kaprodi dan Admin
  # membuka data seluruh prodi/instalasi, jadi hanya diberikan oleh admin
  # lewat Konfigurasi → Pengguna (sunting atau impor CSV).
  SELF_REGISTRABLE_CODES = %w[mahasiswa dosen preseptor].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :self_registrable, -> { where(code: SELF_REGISTRABLE_CODES) }

  def self.self_registrable?(code)
    SELF_REGISTRABLE_CODES.include?(code.to_s)
  end

  # Urutan tetap mengikuti SELF_REGISTRABLE_CODES, bukan urutan id di basis data.
  def self.self_registrable_options
    by_code = self_registrable.index_by(&:code)
    SELF_REGISTRABLE_CODES.filter_map { |code| by_code[code] }.map { |role| [ role.name, role.code ] }
  end
end
