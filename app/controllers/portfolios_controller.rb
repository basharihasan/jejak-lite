# frozen_string_literal: true

require "csv"

class PortfoliosController < ApplicationController
  before_action :authenticate_user!

  def show
    @logs = current_user.activity_logs
    @total = @logs.count
    @klinis_count = @logs.klinis.count
    @non_klinis_count = @logs.non_klinis.count
    @monthly_counts = @logs.group_by_month(:activity_date, last: 6).count
    # Kegiatan baru tidak lagi mengisi teks bebas activity_type — hitung dari
    # taksonomi (Bentuk Kegiatan → Subdomain), teks lama sebagai cadangan.
    @type_counts = @logs.with_taxonomy.filter_map(&:kind_label).tally.sort_by { |_, c| -c }.first(8)
  end

  def export
    logs = current_user.activity_logs.recent.with_taxonomy.includes(:academic_period, :clinical_rotation)

    csv = CSV.generate(headers: true) do |rows|
      rows << [ "Tanggal", "Waktu Mulai", "Waktu Selesai", "Domain", "Subdomain / Kategori", "Bentuk Kegiatan",
                "Klinis/Non-Klinis", "Topik", "Lokasi", "Metode", "Semester", "Rotasi", "Catatan", "Refleksi",
                "Jumlah Peserta", "Link Bukti", "Link Dokumen" ]
      logs.each do |log|
        rows << [ log.activity_date, log.started_at&.strftime("%H:%M"), log.ended_at&.strftime("%Y-%m-%d %H:%M"),
                  log.domain_label, log.academic_activity_subdomain&.name || log.activity_type,
                  log.academic_activity_template&.name, log.category_label, log.title, log.location,
                  log.delivery_mode_label, log.academic_period&.name, log.clinical_rotation&.station_name,
                  log.description, log.reflection, log.participant_count, log.evidence_url, log.document_url ]
      end
    end

    send_data csv, filename: "portfolio-#{current_user.full_name.parameterize}-#{Date.current}.csv"
  end
end
