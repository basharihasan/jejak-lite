# frozen_string_literal: true

# Konfigurasi → Data Governance: sakelar Contextual Privacy Mode dan jejak
# audit Break Glass. Admin saja.
class Admin::DataGovernanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def show
    @privacy_mode = AppSetting.privacy_mode?
    @privacy_row = AppSetting.privacy_mode_row
    @locked_by_env = AppSetting.privacy_mode_locked_by_env?
    @accesses = BreakGlassAccess.includes(:user, clinical_case: :user).recent.limit(100)
    @cases_with_identity = ClinicalCase.where.not(patient_name: nil).count
  end

  def update
    if AppSetting.privacy_mode_locked_by_env?
      redirect_to admin_data_governance_path, alert: "Privacy Mode dikunci oleh variabel lingkungan PRIVACY_MODE."
      return
    end

    AppSetting.set_privacy_mode!(params[:privacy_mode], by: current_user)
    state = AppSetting.privacy_mode? ? "dinyalakan" : "dimatikan"
    redirect_to admin_data_governance_path, notice: "Privacy Mode #{state} oleh #{current_user.full_name}."
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end
end
