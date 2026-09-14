# frozen_string_literal: true

# "Analisis Capaian Pembelajaran" — potret pribadi SATU periode akademik,
# bukan tren rata-rata antar tahun. Tren semacam itu SELALU menyesatkan
# karena bobot & jenis asesmen berganti tiap periode (lihat memori:
# assessment-type-mix-shifts-per-period). Jadi halaman ini sengaja tidak
# punya grafik "kemajuan dari waktu ke waktu".
class AcademicAssessmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @academic_periods = AcademicPeriod.ordered
    @selected_period = if params[:academic_period_id].present?
      @academic_periods.find(params[:academic_period_id])
    else
      @academic_periods.current.first || @academic_periods.first
    end

    if @selected_period
      rotation_ids = ClinicalRotation.for_student(current_user).where(academic_period: @selected_period).pluck(:id)

      @dops_evaluations = DopsEvaluation.where(student: current_user, clinical_rotation_id: rotation_ids).submitted.recent
      @mini_cex_evaluations = MiniCexEvaluation.where(student: current_user, clinical_rotation_id: rotation_ids).submitted.recent
      @exam_scores = current_user.assessment_instances.scored.in_period(@selected_period)
                                 .includes(:assessment_event).sort_by(&:effective_date)

      @dops_radar = DopsEvaluation.avg_dimension_scores(@dops_evaluations) if @dops_evaluations.any?
      @mini_cex_radar = MiniCexEvaluation.avg_dimension_scores(@mini_cex_evaluations) if @mini_cex_evaluations.any?
      @overall_average = overall_average(@dops_evaluations, @mini_cex_evaluations)
      @milestones = CompetencyMilestone.where(academic_period: @selected_period).includes(:competency_item)
      # Pilar C: nilai blok dari Assessment Matrix & posisi terhadap kohort.
      @learning_units = LearningUnit.for_student(current_user)
                                    .where(academic_period_id: [ nil, @selected_period.id ])
                                    .includes(assessment_mappings: :assessment_event).ordered
                                    .map { |u| { unit: u, score: u.score_for(current_user), components: u.components_for(current_user) } }
                                    .select { |row| row[:score] }
      @percentiles = CohortPercentileCalculator.new(student: current_user, period: @selected_period).call
    else
      @dops_evaluations = DopsEvaluation.none
      @mini_cex_evaluations = MiniCexEvaluation.none
      @exam_scores = []
      @milestones = CompetencyMilestone.none
      @learning_units = []
      @percentiles = []
    end
  end

  private

  # Milestone dibandingkan dengan rata-rata KESELURUHAN DOPS+Mini-CEX
  # mahasiswa periode ini — BUKAN skor spesifik ranah kompetensi itu,
  # karena jejak-lite sengaja tidak membangun linkage skor-per-domain
  # (lihat IMPLEMENTATION_PLAN.md § Fase 20). Ini proksi capaian umum,
  # dilabeli jelas sebagai itu di tampilan, bukan diklaim presisi per-ranah.
  def overall_average(dops_scope, mini_cex_scope)
    scores = dops_scope.filter_map(&:average_score) + mini_cex_scope.filter_map(&:average_score)
    return nil if scores.empty?

    (scores.sum / scores.size).round(1)
  end
end
