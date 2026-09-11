# frozen_string_literal: true

class FinalProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_final_project, only: %i[show edit update destroy]

  def index
    @final_projects = policy_scope(FinalProject).includes(:student, :supervisor).order(created_at: :desc)
  end

  def show
    authorize @final_project
  end

  def new
    authorize FinalProject
    @final_project = current_user.final_projects.build
  end

  def create
    authorize FinalProject
    @final_project = current_user.final_projects.build(final_project_params)

    if @final_project.save
      redirect_to @final_project, notice: "Tugas akhir berhasil didaftarkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @final_project
    load_supervisors
  end

  def update
    authorize @final_project
    if @final_project.update(final_project_params)
      redirect_to @final_project, notice: "Tugas akhir diperbarui."
    else
      load_supervisors
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @final_project
    @final_project.destroy
    redirect_to final_projects_path, notice: "Tugas akhir dihapus.", status: :see_other
  end

  private

  def set_final_project
    @final_project = FinalProject.find(params[:id])
  end

  def load_supervisors
    @supervisors = User.joins(:roles).where(roles: { code: "dosen" }).order(:full_name)
  end

  def final_project_params
    params.require(:final_project).permit(:title, :description, :status, :supervisor_id)
  end
end
