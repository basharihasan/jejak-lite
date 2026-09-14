# frozen_string_literal: true

# Lembar penguji: antrean percobaan yang ditugaskan kepada saya (atau belum
# bertugas & sudah dikumpulkan — dosen/preseptor/kaprodi/admin boleh
# mengambil), lalu isi nilai + umpan balik "pertahankan / tingkatkan".
class ExaminerEvaluationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_instructor!
  before_action :set_instance, only: %i[show update]

  def index
    @mine = AssessmentInstance.for_examiner(current_user).includes(:student, :assessment_event).order(Arel.sql("CASE status WHEN 'scored' THEN 1 ELSE 0 END"), :submitted_at)
    @unassigned = AssessmentInstance.where(examiner_id: nil, status: "submitted").includes(:student, :assessment_event).order(:submitted_at)
  end

  def show; end

  def update
    unless can_score?(@instance)
      redirect_to examiner_evaluations_path, alert: "Percobaan ini ditugaskan ke penguji lain."
      return
    end

    p = params.require(:assessment_instance).permit(:score, :feedback_keep, :feedback_improve)
    if p[:score].blank?
      redirect_to examiner_evaluation_path(@instance), alert: "Isi nilai terlebih dahulu."
      return
    end

    @instance.score!(score: p[:score], examiner: current_user, feedback_keep: p[:feedback_keep], feedback_improve: p[:feedback_improve],
                     source: @instance.assessment_event.assessment_form_template ? "rubric" : "manual")
    redirect_to examiner_evaluations_path, notice: "Nilai #{@instance.student.full_name} tersimpan."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to examiner_evaluation_path(@instance), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def require_instructor!
    return if current_user.instructor? || current_user.has_role?("kaprodi")

    redirect_to dashboard_path, alert: "Halaman ini untuk dosen/preseptor."
  end

  def set_instance
    @instance = AssessmentInstance.includes(:student, :assessment_event, :clinical_case).find(params[:id])
  end

  def can_score?(instance)
    instance.examiner_id.nil? || instance.examiner_id == current_user.id || current_user.has_role?("admin")
  end
end
