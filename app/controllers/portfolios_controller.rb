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
    @type_counts = @logs.where.not(activity_type: [ nil, "" ]).group(:activity_type).count.sort_by { |_, c| -c }.first(8)
  end

  def export
    logs = current_user.activity_logs.recent

    csv = CSV.generate(headers: true) do |rows|
      rows << [ "Tanggal", "Kategori", "Jenis", "Judul", "Deskripsi", "Refleksi", "Jumlah Peserta" ]
      logs.each do |log|
        rows << [ log.activity_date, log.category_label, log.activity_type, log.title, log.description, log.reflection, log.participant_count ]
      end
    end

    send_data csv, filename: "portfolio-#{current_user.full_name.parameterize}-#{Date.current}.csv"
  end
end
