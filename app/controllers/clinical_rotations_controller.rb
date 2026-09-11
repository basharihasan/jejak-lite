# frozen_string_literal: true

class ClinicalRotationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_clinical_rotation, only: %i[edit update destroy]

  def index
    @rotations = policy_scope(ClinicalRotation).includes(:academic_period, :preceptor, :user).order(start_date: :desc)
  end

  def new
    authorize ClinicalRotation
    @clinical_rotation = ClinicalRotation.new
    load_form_collections
  end

  def create
    authorize ClinicalRotation
    @clinical_rotation = ClinicalRotation.new(clinical_rotation_params)

    if @clinical_rotation.save
      redirect_to clinical_rotations_path, notice: "Rotasi berhasil ditambahkan."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @clinical_rotation
    load_form_collections
  end

  def update
    authorize @clinical_rotation
    if @clinical_rotation.update(clinical_rotation_params)
      redirect_to clinical_rotations_path, notice: "Rotasi berhasil diperbarui."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @clinical_rotation
    @clinical_rotation.destroy
    redirect_to clinical_rotations_path, notice: "Rotasi dihapus.", status: :see_other
  end

  private

  def set_clinical_rotation
    @clinical_rotation = ClinicalRotation.find(params[:id])
  end

  def load_form_collections
    @students = User.joins(:roles).where(roles: { code: "mahasiswa" }).order(:full_name)
    @preceptors = User.joins(:roles).where(roles: { code: "dosen" }).order(:full_name)
    @academic_periods = AcademicPeriod.ordered
  end

  def clinical_rotation_params
    params.require(:clinical_rotation).permit(
      :user_id, :academic_period_id, :preceptor_id, :station_name, :institution_name, :start_date, :end_date
    )
  end
end
