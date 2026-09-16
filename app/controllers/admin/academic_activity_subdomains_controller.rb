# frozen_string_literal: true

# Subdomain / Kategori di bawah satu domain kegiatan. Dikelola dari halaman
# Domain Kegiatan Akademik; domain induknya tidak bisa dipindah.
class Admin::AcademicActivitySubdomainsController < Admin::BaseController
  include TaxonomyAdminActions

  before_action :set_domain, only: %i[new create]
  before_action :set_record, only: %i[edit update destroy move toggle_active]
  helper_method :record_label

  def new
    @record = @domain.academic_activity_subdomains.build
  end

  def create
    @record = @domain.academic_activity_subdomains.build(record_params)
    if @record.save
      redirect_to index_anchor, notice: "Subdomain “#{@record.name}” ditambahkan ke #{@domain.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_domain
    @domain = AcademicActivityDomain.find(params[:academic_activity_domain_id])
  end

  def set_record
    @record = AcademicActivitySubdomain.find(params[:id])
    @domain = @record.academic_activity_domain
  end

  def record_params
    params.require(:academic_activity_subdomain).permit(:name, :is_active)
  end

  def record_label = "Subdomain"
  def anchor_domain_id = @domain.id
end
