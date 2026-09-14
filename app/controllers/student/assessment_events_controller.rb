# frozen_string_literal: true

# Mahasiswa mendaftar sendiri ke event berbasis rubrik yang tampil untuknya
# (membuat percobaan baru). Event impor (CBT/OSCE) tidak bisa didaftar
# sendiri — nilainya masuk lewat admin.
class Student::AssessmentEventsController < ApplicationController
  before_action :authenticate_user!

  def register
    event = AssessmentEvent.find(params[:id])
    unless event.visible_to?(current_user) && event.submission_open? && !event.importable? && !event.case_based?
      redirect_to student_assessments_path, alert: "Event ini tidak tersedia untuk didaftar."
      return
    end

    existing = current_user.assessment_instances.where(assessment_event: event)
    if existing.any? && !event.allow_multiple_attempts?
      redirect_to student_assessment_path(existing.first), alert: "Anda sudah terdaftar pada event ini."
      return
    end
    if existing.any? && existing.where.not(status: "scored").exists?
      redirect_to student_assessments_path, alert: "Selesaikan percobaan yang masih berjalan sebelum mendaftar ulang."
      return
    end

    instance = current_user.assessment_instances.create!(
      assessment_event: event, attempt_number: AssessmentInstance.next_attempt_number(event, current_user),
      max_score: event.max_score
    )
    redirect_to student_assessment_path(instance), notice: "Terdaftar pada #{event.name} (percobaan ke-#{instance.attempt_number})."
  end
end
