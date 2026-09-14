# frozen_string_literal: true

class StudyProgramsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_program, only: %i[edit update]

  def index
    authorize StudyProgram
    @study_programs = StudyProgram.ordered.includes(:users)
  end

  def new
    authorize StudyProgram
    @study_program = StudyProgram.new(level: "sarjana")
  end

  def create
    authorize StudyProgram
    @study_program = StudyProgram.new(study_program_params)
    if @study_program.save
      redirect_to study_programs_path, notice: "Program studi berhasil ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @study_program
  end

  def update
    authorize @study_program
    if @study_program.update(study_program_params)
      redirect_to study_programs_path, notice: "Program studi berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_study_program
    @study_program = StudyProgram.find(params[:id])
  end

  def study_program_params
    params.require(:study_program).permit(:name, :code, :level)
  end
end
