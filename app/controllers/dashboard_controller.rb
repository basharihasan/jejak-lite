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
      { title: "Dashboard Analitik mahasiswa bimbingan", path: :analytics_path }
    ],
    "preseptor" => [
      { title: "Lengkapi profil", path: :profile_path },
      { title: "Dashboard Analitik mahasiswa di wahana", path: :analytics_path }
    ],
    "kaprodi" => [
      { title: "Lengkapi profil", path: :profile_path },
      { title: "Dashboard Analitik program studi", path: :analytics_path }
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
    @upcoming_schedules = EvaluationSchedule.for_user(current_user).upcoming.includes(:student, :evaluator).limit(3)
    @pending_assessments = current_user.assessment_instances.awaiting_score.includes(:assessment_event).recent.limit(3)

    load_instructor_quick_actions if current_user.instructor?
    load_own_competency_radar
  end

  private

  # Ringkasan "pekerjaan menunggu" langsung dari dashboard, bukan cuma link
  # statis — meniru pola JEJAK asli (quick-action ke evaluasi pending/kasus
  # menunggu verifikasi) sehingga dosen/preseptor/admin langsung tahu ada
  # yang perlu dikerjakan tanpa membuka tiap halaman satu-satu.
  def load_instructor_quick_actions
    @draft_evaluations_count = DopsEvaluation.draft.where(evaluator: current_user).count +
                                MiniCexEvaluation.draft.where(evaluator: current_user).count
    @pending_verifications_count = ClinicalCase.awaiting_verification.count
  end

  def load_own_competency_radar
    dops_scores = current_user.dops_evaluations_as_student.submitted
    @own_dops_radar = DopsEvaluation.avg_dimension_scores(dops_scores) if dops_scores.any?

    mini_cex_scores = current_user.mini_cex_evaluations_as_student.submitted
    @own_mini_cex_radar = MiniCexEvaluation.avg_dimension_scores(mini_cex_scores) if mini_cex_scores.any?
  end
end
