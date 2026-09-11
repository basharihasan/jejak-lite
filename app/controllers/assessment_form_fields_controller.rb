# frozen_string_literal: true

class AssessmentFormFieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template
  before_action :set_field, only: %i[edit update destroy]

  def new
    authorize @template, :manage?
    @field = @template.assessment_form_fields.build
  end

  def create
    authorize @template, :manage?
    @field = @template.assessment_form_fields.build(field_params)

    if @field.save
      redirect_to @template, notice: "Pertanyaan ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @template, :manage?
  end

  def update
    authorize @template, :manage?
    if @field.update(field_params)
      redirect_to @template, notice: "Pertanyaan diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @template, :manage?
    @field.destroy
    redirect_to @template, notice: "Pertanyaan dihapus.", status: :see_other
  end

  private

  def set_template
    @template = AssessmentFormTemplate.find(params[:assessment_form_template_id])
  end

  def set_field
    @field = @template.assessment_form_fields.find(params[:id])
  end

  def field_params
    params.require(:assessment_form_field).permit(:label, :field_type, :required)
  end
end
