# frozen_string_literal: true

# Satu baris mapping ditambah/dihapus lewat form inline di halaman detail
# blueprint — pola yang sama persis dipakai CompetencyItemsController untuk
# menambah ranah/sub-kompetensi (konsisten, tanpa JS dinamis baru).
class AssessmentBlueprintMappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assessment_blueprint

  def create
    authorize AssessmentBlueprintMapping
    mapping = @assessment_blueprint.assessment_blueprint_mappings.new(mapping_params)

    if mapping.save
      redirect_to assessment_blueprint_path(@assessment_blueprint), notice: "Mapping kompetensi ditambahkan."
    else
      redirect_to assessment_blueprint_path(@assessment_blueprint), alert: mapping.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize AssessmentBlueprintMapping
    @assessment_blueprint.assessment_blueprint_mappings.find(params[:id]).destroy
    redirect_to assessment_blueprint_path(@assessment_blueprint), notice: "Mapping kompetensi dihapus.", status: :see_other
  end

  private

  def set_assessment_blueprint
    @assessment_blueprint = AssessmentBlueprint.find(params[:assessment_blueprint_id])
  end

  def mapping_params
    params.require(:assessment_blueprint_mapping).permit(:competency_item_id, :weight)
  end
end
