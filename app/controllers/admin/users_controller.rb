# frozen_string_literal: true

# Konfigurasi → Pengguna: daftar, sunting peran/prodi, reset kata sandi ke
# bawaan, dan impor CSV. Gerbangnya has_role?("admin") — sama dengan policy
# halaman konfigurasi lain, bukan peran aktif.
class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: %i[edit update reset_password]

  def index
    @query = params[:q].to_s.strip
    @role_code = params[:role].presence
    @study_program_id = params[:study_program_id].presence

    scope = User.includes(:roles, :study_program).order(:full_name)
    if @query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      scope = scope.where("full_name ILIKE :q OR email ILIKE :q", q: like)
    end
    scope = scope.joins(:roles).where(roles: { code: @role_code }).distinct if @role_code
    scope = scope.where(study_program_id: @study_program_id) if @study_program_id

    @users = scope.page(params[:page]).per(25)
    @roles = Role.order(:name)
    @study_programs = StudyProgram.ordered
  end

  def edit
    load_form_collections
  end

  def update
    role_ids = Array(params.dig(:user, :role_ids)).reject(&:blank?).map(&:to_i)
    if role_ids.empty?
      @user.errors.add(:base, "Pengguna harus memiliki minimal satu peran.")
      load_form_collections
      return render :edit, status: :unprocessable_entity
    end

    User.transaction do
      @user.update!(user_params)
      @user.role_ids = role_ids
      @user.update!(active_role_id: role_ids.first) unless role_ids.include?(@user.active_role_id)
    end
    redirect_to admin_users_path, notice: "Data #{@user.full_name} diperbarui."
  rescue ActiveRecord::RecordInvalid
    load_form_collections
    render :edit, status: :unprocessable_entity
  end

  def reset_password
    @user.update!(password: User::DEFAULT_PASSWORD, password_confirmation: User::DEFAULT_PASSWORD)
    redirect_to edit_admin_user_path(@user), notice: "Kata sandi #{@user.full_name} direset ke kata sandi bawaan.", status: :see_other
  end

  def import; end

  def import_create
    file = params[:file]
    if file.blank?
      redirect_to import_admin_users_path, alert: "Pilih berkas CSV terlebih dahulu."
      return
    end

    @result = UserCsvImporter.new(file).call
    render :import, status: (@result.errors.any? && @result.created.empty? && @result.updated.empty? ? :unprocessable_entity : :ok)
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  def set_user
    @user = User.find(params[:id])
  end

  def load_form_collections
    @roles = Role.order(:name)
    @study_programs = StudyProgram.ordered
  end

  def user_params
    params.require(:user).permit(:full_name, :study_program_id)
  end
end
