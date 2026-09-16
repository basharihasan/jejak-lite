# frozen_string_literal: true

# Konfigurasi → Taksonomi Istilah (jejak.pro: /admin/terminology). Admin
# mengganti label menu sidebar dan istilah halaman Logbook Kegiatan; isian
# kosong = kembali ke label bawaan.
class Admin::TerminologyOverridesController < Admin::BaseController
  def index
    @entries = Terminology.entries.group_by(&:section)
    @overrides = TerminologyOverride.includes(:updated_by).index_by(&:key)
    @submitted = {}
  end

  def update
    values = params.fetch(:terms, {}).permit(*Terminology.keys).to_h
    errors = TerminologyOverride.apply!(values, by: current_user)

    if errors.empty?
      redirect_to admin_terminology_path, notice: "Label menu & istilah disimpan."
    else
      @entries = Terminology.entries.group_by(&:section)
      @overrides = TerminologyOverride.includes(:updated_by).index_by(&:key)
      @submitted = values
      flash.now[:alert] = "Belum disimpan: #{errors.first(3).to_sentence}"
      render :index, status: :unprocessable_entity
    end
  end
end
