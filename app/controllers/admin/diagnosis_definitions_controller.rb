# frozen_string_literal: true

class Admin::DiagnosisDefinitionsController < Admin::MasterDataBaseController
  helper_method :resource_label, :index_path

  private

  def model = DiagnosisDefinition
  def resource_label = "Diagnosis"
  def index_path = admin_diagnosis_definitions_path

  def record_params
    params.require(:diagnosis_definition).permit(:name, :icd10_code, :skdi_level, :system_group, :active)
  end
end
