# frozen_string_literal: true

class AssessmentBlueprintsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assessment_blueprint, only: %i[show edit update destroy]

  def index
    authorize AssessmentBlueprint
    @assessment_blueprints = AssessmentBlueprint.order(:name)
  end

  def show
    authorize @assessment_blueprint
  end

  def new
    authorize AssessmentBlueprint
    @assessment_blueprint = AssessmentBlueprint.new
  end

  def create
    authorize AssessmentBlueprint
    @assessment_blueprint = AssessmentBlueprint.new(assessment_blueprint_params)

    if @assessment_blueprint.save
      redirect_to assessment_blueprints_path, notice: "Blueprint asesmen ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @assessment_blueprint
  end

  def update
    authorize @assessment_blueprint
    if @assessment_blueprint.update(assessment_blueprint_params)
      redirect_to assessment_blueprints_path, notice: "Blueprint asesmen diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @assessment_blueprint
    @assessment_blueprint.destroy
    redirect_to assessment_blueprints_path, notice: "Blueprint asesmen dihapus.", status: :see_other
  end

  private

  def set_assessment_blueprint
    @assessment_blueprint = AssessmentBlueprint.find(params[:id])
  end

  # competency_mapping & learning_outcomes ditulis sebagai baris teks
  # ("Ranah: Bobot" per baris) supaya tak perlu JS dinamis untuk form
  # sesederhana ini — blueprint tanpa FK ke CompetencyFramework (lihat
  # catatan arsitektur di model AssessmentBlueprint).
  def assessment_blueprint_params
    mapping = {}
    params.dig(:assessment_blueprint, :competency_mapping_text).to_s.split("\n").each do |line|
      label, weight = line.split(":", 2)
      next if label.blank? || weight.blank?

      mapping[label.strip] = weight.strip.to_f
    end

    outcomes = params.dig(:assessment_blueprint, :learning_outcomes_text).to_s
      .split("\n").map(&:strip).reject(&:blank?)

    params.require(:assessment_blueprint).permit(:name, :description)
      .merge(competency_mapping: mapping, learning_outcomes: outcomes)
  end
end
