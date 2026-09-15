# frozen_string_literal: true

class AssessmentFormFieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template
  before_action :set_field, only: %i[edit update destroy move_up move_down]

  def new
    authorize @template, :manage?
    @field = @template.assessment_form_fields.build(field_type: "rating")
    load_competency_choices
  end

  def create
    authorize @template, :manage?
    @field = @template.assessment_form_fields.build(field_params)

    if @field.save
      redirect_to @template, notice: "Pertanyaan ditambahkan."
    else
      load_competency_choices
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @template, :manage?
    load_competency_choices
  end

  def update
    authorize @template, :manage?
    if @field.update(field_params)
      redirect_to @template, notice: "Pertanyaan diperbarui."
    else
      load_competency_choices
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @template, :manage?
    @field.destroy
    redirect_to @template, notice: "Pertanyaan dihapus.", status: :see_other
  end

  def move_up
    authorize @template, :manage?
    @field.move_up!
    redirect_to @template, notice: "Urutan pertanyaan diperbarui.", status: :see_other
  end

  def move_down
    authorize @template, :manage?
    @field.move_down!
    redirect_to @template, notice: "Urutan pertanyaan diperbarui.", status: :see_other
  end

  private

  # Ranah kompetensi beserta sub-kompetensinya, ditampilkan bertingkat.
  def load_competency_choices
    @competency_choices = CompetencyItem.includes(:children).where(parent_id: nil).order(:position).flat_map do |domain|
      [ [ domain.title, domain.id ] ] + domain.children.map { |child| [ "— #{child.title}", child.id ] }
    end
  end

  def set_template
    @template = AssessmentFormTemplate.find(params[:assessment_form_template_id])
  end

  def set_field
    @field = @template.assessment_form_fields.find(params[:id])
  end

  def field_params
    params.require(:assessment_form_field).permit(:label, :field_type, :required, :max_score, :weight, :help_text, :options_text, :competency_item_id)
  end
end
