# frozen_string_literal: true

# Lembar penguji: antrean percobaan yang ditugaskan kepada saya (atau belum
# bertugas & sudah dikumpulkan — dosen/preseptor/kaprodi/admin boleh
# mengambil), lalu isi nilai + umpan balik "pertahankan / tingkatkan".
#
# Bila event memakai rubrik (Assessment Form Builder), penguji mengisi rubrik
# itu DI SINI: jawabannya tersimpan sebagai AssessmentFormSubmission yang
# tertaut ke percobaan, dan nilainya dihitung dari jawaban — bukan diketik
# ulang seperti sebelumnya.
class ExaminerEvaluationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_instructor!
  before_action :set_instance, only: %i[show update]

  def index
    @mine = AssessmentInstance.for_examiner(current_user).includes(:student, :assessment_event)
                              .order(Arel.sql("CASE status WHEN 'scored' THEN 1 ELSE 0 END"), :submitted_at)
    @unassigned = AssessmentInstance.where(examiner_id: nil, status: "submitted").includes(:student, :assessment_event).order(:submitted_at)
  end

  def show
    @template = @instance.assessment_event.assessment_form_template
    @submission = @instance.assessment_form_submission
  end

  def update
    unless can_score?(@instance)
      redirect_to examiner_evaluations_path, alert: "Percobaan ini ditugaskan ke penguji lain."
      return
    end

    @template = @instance.assessment_event.assessment_form_template
    @template && rubric_scored? ? score_with_rubric : score_manually
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

  def feedback_params
    params.fetch(:assessment_instance, {}).permit(:score, :feedback_keep, :feedback_improve)
  end

  # Rubrik dipakai bila templatenya punya pertanyaan bertipe skor; rubrik yang
  # isinya naratif saja tetap disimpan, tetapi nilainya diketik penguji.
  def rubric_scored?
    @template.assessment_form_fields.any?(&:scorable?)
  end

  # Mengisi ulang rubrik menggantikan lembar sebelumnya, bukan menumpuk lembar
  # yatim: satu percobaan = satu lembar rubrik yang berlaku. Lembar lama
  # dibuang DI DALAM transaksi — bila lembar baru gagal validasi, lembar lama
  # (dasar nilai yang sudah keluar) tetap utuh.
  def score_with_rubric
    previous = @instance.assessment_form_submission
    submission = build_submission

    AssessmentInstance.transaction do
      previous&.destroy!
      submission.save!
      percentage = submission.score_percentage
      if percentage.nil?
        submission.errors.add(:base, "Isi minimal satu pertanyaan bernilai pada rubrik.")
        raise ActiveRecord::RecordInvalid, submission
      end
      score = (percentage / 100.0 * @instance.max_score).round(2)
      @instance.assessment_form_submission = submission
      @instance.score!(score: score, examiner: current_user, source: "rubric",
                       feedback_keep: feedback_params[:feedback_keep], feedback_improve: feedback_params[:feedback_improve])
    end

    redirect_to examiner_evaluations_path,
                notice: "Rubrik #{@instance.student.full_name} tersimpan — nilai #{@instance.reload.score} dari #{@instance.max_score} dihitung otomatis dari jawaban."
  rescue ActiveRecord::RecordInvalid => e
    @submission = submission
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  def score_manually
    if feedback_params[:score].blank?
      redirect_to examiner_evaluation_path(@instance), alert: "Isi nilai terlebih dahulu."
      return
    end

    @instance.score!(score: feedback_params[:score], examiner: current_user, source: "manual",
                     feedback_keep: feedback_params[:feedback_keep], feedback_improve: feedback_params[:feedback_improve])
    redirect_to examiner_evaluations_path, notice: "Nilai #{@instance.student.full_name} tersimpan."
  end

  def build_submission
    submitted = params[:answers] || {}
    submission = @template.assessment_form_submissions.build(
      respondent: current_user, subject_user: @instance.student, submitted_at: Time.current,
      subject_label: @instance.assessment_event.name
    )
    @template.assessment_form_fields.ordered.each do |field|
      submission.assessment_form_answers.build(assessment_form_field: field, value: submitted[field.id.to_s])
    end
    submission
  end
end
