# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |user|
      assign_initial_role(user) if user.persisted?
    end
  end

  private

  # role_code cuma dipakai assign_initial_role, bukan kolom User — kalau
  # dibiarkan ikut ke User.new (lewat sign_up_params bawaan Devise) akan
  # meledak sebagai ActiveModel::UnknownAttributeError.
  def sign_up_params
    super.except(:role_code)
  end

  # Form registrasi mengirim satu `role_code` (mis. "mahasiswa"/"dosen").
  # Peran lain bisa ditambahkan belakangan lewat pengaturan; ini hanya
  # menjamin akun baru langsung punya minimal satu peran aktif supaya
  # Dashboard tidak menemui user tanpa peran sama sekali.
  def assign_initial_role(user)
    role = Role.find_by(code: params.dig(:user, :role_code))
    role ||= Role.find_by(code: "mahasiswa")
    return if role.nil?

    user.roles << role unless user.roles.include?(role)
    user.update_column(:active_role_id, role.id) if user.active_role_id.nil?
  end
end
