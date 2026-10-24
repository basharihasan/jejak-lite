# frozen_string_literal: true

class AssessmentFormTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[show edit update destroy]

  def index
    authorize AssessmentFormTemplate
    @templates = AssessmentFormTemplate.all
  end

  def show
    authorize @template
  end

  def new
    authorize AssessmentFormTemplate, :create?
    @template = AssessmentFormTemplate.new
  end

  def create
    authorize AssessmentFormTemplate, :create?
    @template = AssessmentFormTemplate.new(template_params)
    @template.created_by = current_user

    if @template.save
      redirect_to @template, notice: "Formulir berhasil dibuat. Sekarang tambahkan pertanyaan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @template
  end

  def update
    authorize @template
    if @template.update(template_params)
      redirect_to @template, notice: "Formulir diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Menghapus template ikut menghapus seluruh jawaban & memutus nilai asesmen
  # yang berangkat darinya. Bila sudah dipakai, arahkan ke nonaktifkan.
  def destroy
    authorize @template
    if @template.assessment_form_submissions.exists?
      redirect_to @template, alert: "Formulir ini sudah punya jawaban, jadi tidak dapat dihapus. Nonaktifkan saja lewat Sunting agar tidak dipakai lagi."
      return
    end
    if AssessmentEvent.exists?(assessment_form_template: @template)
      redirect_to @template, alert: "Formulir ini dipakai sebagai rubrik pada Assessment Event. Lepaskan dulu dari event tersebut."
      return
    end

    @template.destroy
    redirect_to assessment_form_templates_path, notice: "Formulir dihapus.", status: :see_other
  end

  private

  def set_template
    @template = AssessmentFormTemplate.find(params[:id])
  end

  def template_params
    params.require(:assessment_form_template).permit(:name, :description, :is_active, :anonymous, :requires_subject_user)
  end
end
