# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_google_omniauth(request.env["omniauth.auth"])

    if user.persisted?
      assign_default_role(user)
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      redirect_to new_user_session_path, alert: "Gagal masuk dengan Google — coba lagi."
    end
  end

  private

  # Akun Google baru tidak melewati form registrasi (jadi tidak pernah
  # mengirim role_code) — beri peran default "mahasiswa" supaya tetap punya
  # satu peran aktif; bisa ditambah/diganti lewat pengaturan setelahnya.
  def assign_default_role(user)
    return if user.active_role_id.present?

    default_role = Role.find_by(code: "mahasiswa")
    return if default_role.nil?

    user.roles << default_role unless user.roles.include?(default_role)
    user.update_column(:active_role_id, default_role.id)
  end
end
