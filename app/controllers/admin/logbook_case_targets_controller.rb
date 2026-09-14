# frozen_string_literal: true

class Admin::LogbookCaseTargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_target, only: %i[edit update destroy]

  def index
    @targets = LogbookCaseTarget.includes(:study_program, :academic_period).ordered
  end

  def new
    @target = LogbookCaseTarget.new(facility_type: "fktp")
    load_collections
  end

  def create
    @target = LogbookCaseTarget.new(target_params)
    if @target.save
      redirect_to admin_logbook_case_targets_path, notice: "Target kasus disimpan."
    else
      load_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_collections
  end

  def update
    if @target.update(target_params)
      redirect_to admin_logbook_case_targets_path, notice: "Target kasus diperbarui."
    else
      load_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @target.destroy
    redirect_to admin_logbook_case_targets_path, notice: "Target kasus dihapus.", status: :see_other
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  def set_target
    @target = LogbookCaseTarget.find(params[:id])
  end

  def load_collections
    @study_programs = StudyProgram.ordered
    @academic_periods = AcademicPeriod.ordered
  end

  def target_params
    params.require(:logbook_case_target).permit(:study_program_id, :academic_period_id, :facility_type, :target_count, :notes)
  end
end
