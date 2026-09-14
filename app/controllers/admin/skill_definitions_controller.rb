# frozen_string_literal: true

class Admin::SkillDefinitionsController < Admin::MasterDataBaseController
  helper_method :resource_label, :index_path

  private

  def model = SkillDefinition
  def resource_label = "Keterampilan"
  def index_path = admin_skill_definitions_path

  def record_params
    params.require(:skill_definition).permit(:name, :skdi_level, :category, :active)
  end
end
