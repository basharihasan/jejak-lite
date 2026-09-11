# frozen_string_literal: true

class AcademicPeriodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_academic_period, only: %i[edit update destroy]

  def index
    authorize AcademicPeriod
    @academic_periods = AcademicPeriod.ordered
  end

  def new
    authorize AcademicPeriod
    @academic_period = AcademicPeriod.new
  end

  def create
    authorize AcademicPeriod
    @academic_period = AcademicPeriod.new(academic_period_params)

    if @academic_period.save
      redirect_to academic_periods_path, notice: "Periode akademik ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @academic_period
  end

  def update
    authorize @academic_period
    if @academic_period.update(academic_period_params)
      redirect_to academic_periods_path, notice: "Periode akademik diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @academic_period
    @academic_period.destroy
    redirect_to academic_periods_path, notice: "Periode akademik dihapus.", status: :see_other
  end

  private

  def set_academic_period
    @academic_period = AcademicPeriod.find(params[:id])
  end

  def academic_period_params
    params.require(:academic_period).permit(:name, :start_date, :end_date)
  end
end
