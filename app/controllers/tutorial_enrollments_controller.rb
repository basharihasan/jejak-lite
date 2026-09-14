# frozen_string_literal: true

class TutorialEnrollmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_enrollment, only: %i[edit update destroy toggle_active]

  def index
    @enrollments = policy_scope(TutorialEnrollment).includes(:academic_period, :tutor, :user).ordered
  end

  def new
    authorize TutorialEnrollment
    @enrollment = TutorialEnrollment.new(academic_period: AcademicPeriod.ordered.first)
    load_form_collections
  end

  def create
    authorize TutorialEnrollment
    @enrollment = TutorialEnrollment.new(enrollment_params)

    if @enrollment.save
      redirect_to tutorial_enrollments_path, notice: "Enrolment tutorial berhasil ditambahkan."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @enrollment
    load_form_collections
  end

  def update
    authorize @enrollment
    if @enrollment.update(enrollment_params)
      redirect_to tutorial_enrollments_path, notice: "Enrolment tutorial berhasil diperbarui."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    authorize @enrollment, :update?
    @enrollment.update!(active: !@enrollment.active)
    redirect_to tutorial_enrollments_path, notice: "Enrolment ditandai #{@enrollment.status_label.downcase}.", status: :see_other
  end

  def destroy
    authorize @enrollment
    @enrollment.destroy
    redirect_to tutorial_enrollments_path, notice: "Enrolment tutorial dihapus.", status: :see_other
  end

  private

  def set_enrollment
    @enrollment = TutorialEnrollment.find(params[:id])
  end

  def load_form_collections
    @students = User.joins(:roles).where(roles: { code: "mahasiswa" }).order(:full_name)
    @tutors = User.joins(:roles).where(roles: { code: "dosen" }).distinct.order(:full_name)
    @academic_periods = AcademicPeriod.ordered
  end

  def enrollment_params
    params.require(:tutorial_enrollment).permit(
      :user_id, :tutor_id, :academic_period_id, :block_name, :group_name, :start_date, :end_date, :active
    )
  end
end
