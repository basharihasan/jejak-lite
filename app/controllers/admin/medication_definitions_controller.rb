# frozen_string_literal: true

class Admin::MedicationDefinitionsController < Admin::MasterDataBaseController
  helper_method :resource_label, :index_path

  private

  def model = MedicationDefinition
  def resource_label = "Obat"
  def index_path = admin_medication_definitions_path

  def record_params
    params.require(:medication_definition).permit(:name, :strength, :dosage_form, :category, :usual_dosage, :active)
  end
end
