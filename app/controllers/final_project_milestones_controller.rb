# frozen_string_literal: true

class FinalProjectMilestonesController < ApplicationController
  before_action :authenticate_user!

  def new
    @final_project = FinalProject.find(params[:final_project_id])
    authorize @final_project, :manage_milestones?
    @milestone = @final_project.final_project_milestones.build
  end

  def create
    @final_project = FinalProject.find(params[:final_project_id])
    authorize @final_project, :manage_milestones?
    @milestone = @final_project.final_project_milestones.build(milestone_params)

    if @milestone.save
      redirect_to @final_project, notice: "Milestone ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def toggle
    @milestone = FinalProjectMilestone.find(params[:id])
    authorize @milestone.final_project, :manage_milestones?
    @milestone.toggle_completed!
    redirect_to @milestone.final_project, notice: @milestone.completed? ? "Milestone ditandai selesai." : "Milestone dibuka kembali."
  end

  def destroy
    @milestone = FinalProjectMilestone.find(params[:id])
    final_project = @milestone.final_project
    authorize final_project, :manage_milestones?
    @milestone.destroy
    redirect_to final_project, notice: "Milestone dihapus.", status: :see_other
  end

  private

  def milestone_params
    params.require(:final_project_milestone).permit(:title, :target_date)
  end
end
