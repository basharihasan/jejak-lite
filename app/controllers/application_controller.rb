class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  around_action :switch_locale

  helper_method :unread_notifications_count, :latest_notifications

  protected

  # Bahasa antarmuka: preferensi akun bila sudah login, lalu cookie (dipakai
  # halaman Devise sebelum login — cookie, bukan session, karena sign-out
  # Devise membuang session), lalu bawaan aplikasi (:id).
  def switch_locale(&action)
    locale = user_signed_in? ? current_user.locale_preference : cookies[:locale]
    locale = I18n.default_locale unless User::LOCALE_OPTIONS.include?(locale.to_s)
    I18n.with_locale(locale, &action)
  end

  # Dipakai topbar (lonceng notifikasi) di setiap halaman yang sudah login —
  # dihitung di sini, bukan tiap view, supaya query-nya satu tempat.
  def unread_notifications_count
    return 0 unless user_signed_in?

    current_user.notifications.unread.active.count
  end

  def latest_notifications
    return Notification.none unless user_signed_in?

    current_user.notifications.active.recent.limit(5)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name, :role_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name ])
  end

  private

  def user_not_authorized
    flash[:alert] = "Anda tidak memiliki akses untuk melakukan itu."
    redirect_back fallback_location: root_path
  end
end
