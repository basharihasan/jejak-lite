# frozen_string_literal: true

# Kerangka bersama CRUD master data admin (Diagnosis, Keterampilan). Subclass
# menetapkan model, parameter yang diizinkan, dan label.
class Admin::MasterDataBaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_record, only: %i[edit update destroy]

  def index
    @query = params[:q].to_s.strip
    @records = model.search(@query).ordered.page(params[:page]).per(50)
  end

  def new
    @record = model.new(active: true)
  end

  def create
    @record = model.new(record_params)
    if @record.save
      redirect_to index_path, notice: "#{resource_label} berhasil ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @record.update(record_params)
      redirect_to index_path, notice: "#{resource_label} berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy
    redirect_to index_path, notice: "#{resource_label} dihapus.", status: :see_other
  end

  # Impor CSV: header sesuai kolom model; baris dengan nama yang sudah ada
  # diperbarui, bukan digandakan.
  def import
    file = params[:file]
    if file.blank?
      redirect_to index_path, alert: "Pilih berkas CSV terlebih dahulu."
      return
    end

    result = MasterDataCsvImporter.new(model, file).call
    msg = "#{result[:created]} baru, #{result[:updated]} diperbarui"
    msg += ", #{result[:errors].size} baris gagal: #{result[:errors].first(3).join('; ')}" if result[:errors].any?
    redirect_to index_path, notice: "Impor #{resource_label.downcase}: #{msg}."
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  def set_record
    @record = model.find(params[:id])
  end
end
