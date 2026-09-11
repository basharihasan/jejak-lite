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
    @academic_periods = AcademicPeriod.ordered
    @selected_period = selected_academic_period

    @mentee_snapshots = mentee_snapshots.sort_by { |s| risk_rank(s) } if show_lecturer_section?
    @preceptor_rotation_snapshots = preceptor_rotation_snapshots if show_preceptor_section?

    if show_program_section?
      @study_programs = accessible_study_programs
      @selected_program = selected_study_program
      @program_snapshots = @selected_program ? program_student_snapshots(@selected_program).sort_by { |s| risk_rank(s) } : []
      @program_radar = program_radar(@selected_program) if @selected_program && @selected_period
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

  def selected_academic_period
    return nil if @academic_periods.empty?
    return @academic_periods.find { |p| p.id == params[:academic_period_id].to_i } if params[:academic_period_id].present?

    @academic_periods.detect { |p| p.start_date <= Date.current && p.end_date >= Date.current } || @academic_periods.first
  end

  # Mahasiswa tanpa data sama sekali diletakkan di AKHIR (rank tinggi),
  # bukan dianggap "paling berisiko" — beda dari sekadar belum ada skor.
  # Yang punya skor rendah (rata-rata DOPS/Mini-CEX) muncul paling atas,
  # meniru pola sort-by-risiko JEJAK asli tanpa perlu model EWS terpisah.
  def risk_rank(snapshot)
    scores = [ snapshot[:avg_dops], snapshot[:avg_mini_cex] ].compact
    return 100 if scores.empty?

    scores.sum / scores.size.to_f
  end

  def mentee_snapshots
    dops_evaluator_scope = current_user.dops_evaluations_as_evaluator
    mini_cex_evaluator_scope = current_user.mini_cex_evaluations_as_evaluator
    if @selected_period
      dops_evaluator_scope = dops_evaluator_scope.joins(:clinical_rotation).where(clinical_rotations: { academic_period_id: @selected_period.id })
      mini_cex_evaluator_scope = mini_cex_evaluator_scope.joins(:clinical_rotation).where(clinical_rotations: { academic_period_id: @selected_period.id })
    end

    student_ids = current_user.supervised_final_projects.pluck(:student_id) +
                  dops_evaluator_scope.pluck(:student_id) +
                  mini_cex_evaluator_scope.pluck(:student_id)

    User.where(id: student_ids.uniq).order(:full_name).map { |student| student_snapshot(student) }
  end

  def preceptor_rotation_snapshots
    scope = ClinicalRotation.for_preceptor(current_user).chronological.includes(:user)
    scope = scope.where(academic_period: @selected_period) if @selected_period

    scope.map do |rotation|
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

  def program_radar(program)
    student_ids = User.joins(:roles).where(roles: { code: "mahasiswa" }, study_program: program).pluck(:id)
    return nil if student_ids.empty?

    rotation_ids = ClinicalRotation.where(user_id: student_ids, academic_period: @selected_period).pluck(:id)
    dops = DopsEvaluation.where(clinical_rotation_id: rotation_ids).submitted
    mini_cex = MiniCexEvaluation.where(clinical_rotation_id: rotation_ids).submitted

    {
      dops: dops.exists? ? DopsEvaluation.avg_dimension_scores(dops) : nil,
      mini_cex: mini_cex.exists? ? MiniCexEvaluation.avg_dimension_scores(mini_cex) : nil
    }
  end

  def student_snapshot(student)
    rotation_scope = ClinicalRotation.for_student(student)
    rotation_scope = rotation_scope.where(academic_period: @selected_period) if @selected_period
    rotation_ids = rotation_scope.pluck(:id)

    dops_scores = DopsEvaluation.where(student: student, clinical_rotation_id: rotation_ids).submitted.filter_map(&:average_score)
    mini_cex_scores = MiniCexEvaluation.where(student: student, clinical_rotation_id: rotation_ids).submitted.filter_map(&:average_score)

    activity_scope = @selected_period ? student.activity_logs.where(activity_date: @selected_period.start_date..@selected_period.end_date) : student.activity_logs.in_month(Date.current)
    case_scope = @selected_period ? student.clinical_cases.where(case_date: @selected_period.start_date..@selected_period.end_date) : student.clinical_cases

    {
      user: student,
      activity_logs_this_month: activity_scope.count,
      avg_dops: dops_scores.any? ? (dops_scores.sum / dops_scores.size).round(1) : nil,
      avg_mini_cex: mini_cex_scores.any? ? (mini_cex_scores.sum / mini_cex_scores.size).round(1) : nil,
      cases_total: case_scope.count,
      cases_verified: case_scope.where(status: "verified").count
    }
  end
end
