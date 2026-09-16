# frozen_string_literal: true

# Aksi bersama tiga controller Domain Kegiatan Akademik (domain, subdomain,
# bentuk kegiatan). Semua aksi kembali ke satu halaman indeks, dengan jangkar
# ke kartu domain yang disentuh.
module TaxonomyAdminActions
  extend ActiveSupport::Concern

  def edit; end

  def update
    if @record.update(record_params)
      redirect_to index_anchor, notice: "#{record_label} “#{@record.name}” diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @record.destroy
      redirect_to index_anchor, notice: "#{record_label} “#{@record.name}” dihapus.", status: :see_other
    else
      redirect_to index_anchor, status: :see_other,
                  alert: "#{record_label} “#{@record.name}” tidak bisa dihapus karena sudah dipakai " \
                         "#{@record.activity_logs.count} kegiatan. Nonaktifkan saja supaya tidak muncul lagi di form."
    end
  end

  def move
    @record.move!(params[:direction])
    redirect_to index_anchor, status: :see_other
  end

  def toggle_active
    @record.update!(is_active: !@record.is_active?)
    state = @record.is_active? ? "diaktifkan" : "dinonaktifkan"
    redirect_to index_anchor, notice: "#{record_label} “#{@record.name}” #{state}.", status: :see_other
  end

  private

  def index_anchor
    admin_academic_activity_domains_path(anchor: "domain-#{anchor_domain_id}")
  end
end
