# frozen_string_literal: true

class CompetencyFrameworksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_competency_framework, only: %i[show edit update destroy]

  def index
    authorize CompetencyFramework
    @competency_frameworks = CompetencyFramework.order(:name)
  end

  def show
    authorize @competency_framework
    @domains = @competency_framework.domains.includes(:children, :competency_milestones)
    @academic_periods = AcademicPeriod.ordered
  end

  def new
    authorize CompetencyFramework
    @competency_framework = CompetencyFramework.new
  end

  def create
    authorize CompetencyFramework
    @competency_framework = CompetencyFramework.new(competency_framework_params)

    if @competency_framework.save
      redirect_to competency_framework_path(@competency_framework), notice: "Peta kompetensi ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @competency_framework
  end

  def update
    authorize @competency_framework
    if @competency_framework.update(competency_framework_params)
      redirect_to competency_framework_path(@competency_framework), notice: "Peta kompetensi diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @competency_framework
    @competency_framework.destroy
    redirect_to competency_frameworks_path, notice: "Peta kompetensi dihapus.", status: :see_other
  end

  private

  def set_competency_framework
    @competency_framework = CompetencyFramework.find(params[:id])
  end

  def competency_framework_params
    params.require(:competency_framework).permit(:name, :description)
  end
end
