class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

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
