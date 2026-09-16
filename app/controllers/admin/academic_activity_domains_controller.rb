# frozen_string_literal: true

# Konfigurasi → Domain Kegiatan Akademik (jejak.pro:
# /admin/academic_activity_domains). Satu halaman untuk seluruh pohon
# Domain → Subdomain / Kategori → Bentuk Kegiatan yang dipakai form Logbook
# Kegiatan dan Kalender.
class Admin::AcademicActivityDomainsController < Admin::BaseController
  include TaxonomyAdminActions

  before_action :set_record, only: %i[edit update destroy move toggle_active]
  helper_method :record_label

  def index
    @domains = AcademicActivityDomain.ordered.includes(academic_activity_subdomains: :academic_activity_templates)
    @usage = {
      domains: ActivityLog.group(:academic_activity_domain_id).count,
      subdomains: ActivityLog.group(:academic_activity_subdomain_id).count,
      templates: ActivityLog.group(:academic_activity_template_id).count
    }
    @unclassified_count = ActivityLog.where(academic_activity_domain_id: nil).count
  end

  def new
    @record = AcademicActivityDomain.new(color_code: AcademicActivityDomain::DEFAULT_COLOR)
  end

  def create
    @record = AcademicActivityDomain.new(record_params)
    if @record.save
      redirect_to admin_academic_activity_domains_path(anchor: "domain-#{@record.id}"),
                  notice: "Domain “#{@record.name}” ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_record
    @record = AcademicActivityDomain.find(params[:id])
  end

  def record_params
    params.require(:academic_activity_domain).permit(:name, :icon, :color_code, :is_clinical, :is_active)
  end

  def record_label = "Domain"
  def anchor_domain_id = @record.id
end
