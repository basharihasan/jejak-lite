# frozen_string_literal: true

# Dashboard Analitik — tiga sudut pandang berbeda dalam satu halaman (bukan
# tiga controller terpisah) karena akun bisa menyandang lebih dari satu
# peran sekaligus (pilar multi-peran jejak-lite): dosen melihat mahasiswa
# bimbingannya, preseptor melihat mahasiswa di rotasi yang dibimbingnya,
# Kaprodi melihat seluruh mahasiswa satu program studi. Admin melihat
# ketiganya sekaligus (tanpa filter kepemilikan).
class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_analytics_access!

  def index
    @mentee_snapshots = mentee_snapshots if show_lecturer_section?
    @preceptor_rotation_snapshots = preceptor_rotation_snapshots if show_preceptor_section?

    if show_program_section?
      @study_programs = accessible_study_programs
      @selected_program = selected_study_program
      @program_snapshots = @selected_program ? program_student_snapshots(@selected_program) : []
    end
  end

  private

  def require_analytics_access!
    return if %w[dosen preseptor kaprodi admin].any? { |code| current_user.has_role?(code) }

    flash[:alert] = "Anda tidak memiliki akses untuk melakukan itu."
    redirect_to dashboard_path
  end

  def show_lecturer_section?
    current_user.has_role?("dosen") || current_user.has_role?("admin")
  end

  def show_preceptor_section?
    current_user.has_role?("preseptor") || current_user.has_role?("admin")
  end

  def show_program_section?
    current_user.has_role?("kaprodi") || current_user.has_role?("admin")
  end

  def mentee_snapshots
    student_ids = current_user.supervised_final_projects.pluck(:student_id) +
                  current_user.dops_evaluations_as_evaluator.pluck(:student_id) +
                  current_user.mini_cex_evaluations_as_evaluator.pluck(:student_id)

    User.where(id: student_ids.uniq).order(:full_name).map { |student| student_snapshot(student) }
  end

  def preceptor_rotation_snapshots
    ClinicalRotation.for_preceptor(current_user).chronological.includes(:user).map do |rotation|
      {
        rotation: rotation,
        activity_logs_during: rotation.user.activity_logs.where(activity_date: rotation.start_date..rotation.end_date).count,
        dops_count: DopsEvaluation.where(clinical_rotation: rotation).count,
        mini_cex_count: MiniCexEvaluation.where(clinical_rotation: rotation).count
      }
    end
  end

  def accessible_study_programs
    current_user.has_role?("admin") ? StudyProgram.order(:name) : [ current_user.study_program ].compact
  end

  def selected_study_program
    return @study_programs.find { |p| p.id == params[:study_program_id].to_i } if params[:study_program_id].present?

    current_user.has_role?("admin") ? @study_programs.first : current_user.study_program
  end

  def program_student_snapshots(program)
    User.joins(:roles).where(roles: { code: "mahasiswa" }, study_program: program).distinct
      .order(:full_name).map { |student| student_snapshot(student) }
  end

  def student_snapshot(student)
    dops_scores = student.dops_evaluations_as_student.filter_map(&:average_score)
    mini_cex_scores = student.mini_cex_evaluations_as_student.filter_map(&:average_score)

    {
      user: student,
      activity_logs_this_month: student.activity_logs.in_month(Date.current).count,
      avg_dops: dops_scores.any? ? (dops_scores.sum / dops_scores.size).round(1) : nil,
      avg_mini_cex: mini_cex_scores.any? ? (mini_cex_scores.sum / mini_cex_scores.size).round(1) : nil,
      cases_total: student.clinical_cases.count,
      cases_verified: student.clinical_cases.where(status: "verified").count
    }
  end
end
