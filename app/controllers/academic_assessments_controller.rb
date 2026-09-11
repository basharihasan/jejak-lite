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

      @dops_evaluations = DopsEvaluation.where(student: current_user, clinical_rotation_id: rotation_ids).recent
      @mini_cex_evaluations = MiniCexEvaluation.where(student: current_user, clinical_rotation_id: rotation_ids).recent
      @exam_scores = ExamScore.where(student: current_user, exam_date: @selected_period.start_date..@selected_period.end_date)
                               .includes(:exam_import).chronological
    else
      @dops_evaluations = DopsEvaluation.none
      @mini_cex_evaluations = MiniCexEvaluation.none
      @exam_scores = ExamScore.none
    end
  end
end
