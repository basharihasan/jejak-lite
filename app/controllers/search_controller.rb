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
      scope = User.where("full_name ILIKE :q OR email ILIKE :q", q: like)
      # Direktori mahasiswa hanya untuk pengajar/kaprodi/admin; selainnya
      # (mahasiswa) hanya menemukan pengajar & pengelola, bukan sesama mahasiswa.
      scope = scope.where(id: UserRole.joins(:role).where.not(roles: { code: "mahasiswa" }).select(:user_id)) unless current_user.can_view_students?
      scope.order(:full_name).limit(20)
    else
      User.none
    end
  end
end
