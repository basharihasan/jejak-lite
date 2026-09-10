# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :authenticate_user!

  # Pencarian global tahap awal: baru mencakup pengguna (nama/email) karena
  # belum ada tipe konten lain (Logbook, Community Feed) yang bisa dicari —
  # begitu Fase 4/5 masuk, hasilnya tinggal ditambah per tipe di sini tanpa
  # mengubah bentuk halaman.
  def index
    @query = params[:q].to_s.strip

    @users = if @query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      User.where("full_name ILIKE :q OR email ILIKE :q", q: like).order(:full_name).limit(20)
    else
      User.none
    end
  end
end
