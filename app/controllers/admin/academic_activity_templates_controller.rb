# frozen_string_literal: true

# Bentuk Kegiatan di bawah satu subdomain (tingkat ketiga, opsional).
class Admin::AcademicActivityTemplatesController < Admin::BaseController
  include TaxonomyAdminActions

  before_action :set_subdomain, only: %i[new create]
  before_action :set_record, only: %i[edit update destroy move toggle_active]
  helper_method :record_label

  def new
    @record = @subdomain.academic_activity_templates.build
  end

  def create
    @record = @subdomain.academic_activity_templates.build(record_params)
    if @record.save
      redirect_to index_anchor, notice: "Bentuk kegiatan “#{@record.name}” ditambahkan ke #{@subdomain.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_subdomain
    @subdomain = AcademicActivitySubdomain.find(params[:academic_activity_subdomain_id])
  end

  def set_record
    @record = AcademicActivityTemplate.find(params[:id])
    @subdomain = @record.academic_activity_subdomain
  end

  def record_params
    params.require(:academic_activity_template).permit(:name, :is_active)
  end

  def record_label = "Bentuk kegiatan"
  def anchor_domain_id = @subdomain.academic_activity_domain_id
end
