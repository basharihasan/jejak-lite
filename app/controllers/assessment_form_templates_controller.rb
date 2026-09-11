# frozen_string_literal: true

class AssessmentFormTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[show edit update destroy]

  def index
    @templates = current_user.has_role?("admin") ? AssessmentFormTemplate.all : AssessmentFormTemplate.active
  end

  def show
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

  def destroy
    authorize @template
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
