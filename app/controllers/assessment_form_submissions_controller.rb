# frozen_string_literal: true

class AssessmentFormSubmissionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @submissions = policy_scope(AssessmentFormSubmission).includes(:assessment_form_template).recent.page(params[:page])
  end

  def show
    @submission = AssessmentFormSubmission.find(params[:id])
    authorize @submission
  end

  def new
    @template = AssessmentFormTemplate.active.find(params[:assessment_form_template_id])
    @submission = @template.assessment_form_submissions.build
    load_subject_candidates
  end

  def create
    @template = AssessmentFormTemplate.active.find(params[:assessment_form_template_id])
    @submission = @template.assessment_form_submissions.build(submission_params)
    @submission.respondent = current_user
    @submission.submitted_at = Time.current
    build_answers

    if @submission.save
      redirect_to assessment_form_template_path(@template), notice: "Terima kasih, jawaban Anda tersimpan."
    else
      load_subject_candidates
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_subject_candidates
    @subject_candidates = User.joins(:roles).where(roles: { code: "dosen" }).distinct.order(:full_name)
  end

  def submission_params
    params.require(:assessment_form_submission).permit(:subject_user_id, :subject_label)
  end

  # Jawaban dikirim sebagai answers[field_id] = value dari form, bukan
  # nested_attributes standar (field_id tidak diketahui sebelumnya karena
  # pertanyaan dinamis per template).
  def build_answers
    (params[:answers] || {}).each do |field_id, value|
      @submission.assessment_form_answers.build(assessment_form_field_id: field_id, value: value)
    end
  end
end
