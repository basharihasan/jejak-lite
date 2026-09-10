# frozen_string_literal: true

# Role — pengganti ringan FunctionalRole/UserPersona/Capability JEJAK.
# Cukup kode + nama tampilan; tidak ada category/domain_permissions/capability
# karena jejak-lite tidak butuh IAM enterprise, hanya "akun ini boleh lihat
# menu apa" lewat has_role?/active_role.
class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
