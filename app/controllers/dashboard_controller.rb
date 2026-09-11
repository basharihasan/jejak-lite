# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  # Kartu "Langkah Berikutnya" per peran. Sengaja hanya berisi hal yang
  # SUDAH ada di aplikasi (Profil, Panduan) — bukan placeholder fitur yang
  # belum dibangun (Logbook/Community Feed baru masuk Fase 4-5). Daftar ini
  # tinggal ditambah begitu fitur barunya nyata.
  ROLE_NEXT_STEPS = {
    "mahasiswa" => [
      { title: "Lengkapi profil", path: :profile_path },
      { title: "Baca Panduan Pengguna", path: :panduan_path }
    ],
    "dosen" => [
      { title: "Lengkapi profil", path: :profile_path },
      { title: "Baca Panduan Pengguna", path: :panduan_path }
    ],
    "admin" => [
      { title: "Lengkapi profil", path: :profile_path },
      { title: "Cari pengguna", path: :search_path }
    ]
  }.freeze

  def show
    @active_role = current_user.active_role
    @next_steps = ROLE_NEXT_STEPS.fetch(@active_role&.code, ROLE_NEXT_STEPS["mahasiswa"])

    @recent_activity_logs = current_user.activity_logs.recent.limit(3)
    @this_month_count = current_user.activity_logs.in_month(Date.current).count
    @unread_notifications = current_user.notifications.unread.active.recent.limit(3)

    @ongoing_rotation = current_user.clinical_rotations.ongoing.first
    @upcoming_rotation = current_user.clinical_rotations.upcoming.first
  end
end
