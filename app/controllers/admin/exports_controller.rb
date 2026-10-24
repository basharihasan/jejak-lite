# frozen_string_literal: true

# Pusat Ekspor Data — unduhan CSV untuk admin (semua prodi) dan kaprodi
# (terikat prodi akunnya). Daftar dataset, kolom, dan cakupan prodinya ada di
# DataExport; controller ini hanya membaca filter dari form, mengirim berkas,
# dan mencatat setiap unduhan ke DataExportLog.
class Admin::ExportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_export_access!

  FILTER_KEYS = %i[study_program_id academic_period_id from to form_template_id csv_format].freeze

  helper_method :prodi_bound_viewer?

  def index
    @datasets = DataExport.datasets_for(current_user).group_by(&:group)
    @study_programs = StudyProgram.ordered
    @academic_periods = AcademicPeriod.ordered
    @form_templates = AssessmentFormTemplate.order(:name)
    @filters = filter_params
    @counts = @datasets.values.flatten.to_h do |dataset|
      [ dataset.key, DataExport.new(dataset.key, viewer: current_user, **@filters).count ]
    end
    logs = DataExportLog.includes(:user).recent
    @logs = (current_user.has_role?("admin") ? logs : logs.where(user: current_user)).limit(20)
  end

  # GET /admin/exports/:id.csv — :id = kunci dataset (mis. activity_logs).
  def show
    filters = filter_params
    return redirect_to admin_exports_path, alert: "Format tanggal tidak dikenali." if @invalid_date
    if filters[:from] && filters[:to] && filters[:from] > filters[:to]
      return redirect_to admin_exports_path(params.slice(*FILTER_KEYS).permit(*FILTER_KEYS)), alert: "Tanggal \"Dari\" harus sebelum tanggal \"Sampai\"."
    end

    export = DataExport.new(params[:id], viewer: current_user, **filters)
    csv = export.to_csv
    DataExportLog.create!(user: current_user, dataset: export.dataset.key,
                          filters: export.applied_filters, row_count: export.row_count)
    send_data csv, filename: export.filename, type: "text/csv; charset=utf-8"
  rescue DataExport::AccessDenied => e
    redirect_to admin_exports_path, alert: e.message
  end

  private

  def require_export_access!
    unless DataExport.allowed?(current_user)
      return redirect_to dashboard_path, alert: "Halaman ini khusus admin/kaprodi."
    end
    return unless prodi_bound_viewer? && current_user.study_program_id.nil?

    redirect_to dashboard_path,
                alert: "Akun kaprodi Anda belum terhubung ke Program Studi — minta admin mengisinya di Konfigurasi → Pengguna."
  end

  def prodi_bound_viewer?
    current_user.study_program_bound?
  end

  def filter_params
    {
      study_program_id: params[:study_program_id].presence,
      academic_period_id: params[:academic_period_id].presence,
      from: parse_date(params[:from]),
      to: parse_date(params[:to]),
      form_template_id: params[:form_template_id].presence,
      format: params[:csv_format].presence || "standard"
    }
  end

  def parse_date(value)
    Date.iso8601(value) if value.present?
  rescue Date::Error
    @invalid_date = true
    nil
  end
end
