# frozen_string_literal: true

class ExaminerScoresController < ApplicationController
  before_action :authenticate_user!

  def new
    @final_project = FinalProject.find(params[:final_project_id])
    authorize @final_project, :score?
    @examiner_score = @final_project.examiner_scores.build(session_date: Date.current)
  end

  def create
    @final_project = FinalProject.find(params[:final_project_id])
    authorize @final_project, :score?
    @examiner_score = @final_project.examiner_scores.build(examiner_score_params)
    @examiner_score.examiner = current_user

    if @examiner_score.save
      redirect_to @final_project, notice: "Skor ujian tersimpan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def examiner_score_params
    params.require(:examiner_score).permit(:session_date, :score, :feedback)
  end
end
