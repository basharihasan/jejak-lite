# frozen_string_literal: true

# Peta EPA & Tingkat Entrustment (/dashboard/entrustment ala jejak.pro):
# mahasiswa melihat levelnya per ranah; pembimbing (tutor/preseptor/dosen/
# admin yang punya relasi) mengisi/memperbarui dengan justifikasi naratif.
class EntrustmentDecisionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_student

  def index
    @framework = CompetencyFramework.order(:id).first
    @map = @framework ? EntrustmentDecision.map_for(@student, @framework) : []
    @history = EntrustmentDecision.where(student: @student).includes(:competency_item, :decided_by, :clinical_case).history.limit(30)
    @can_decide = can_decide?
  end

  def create
    unless can_decide?
      redirect_to entrustment_decisions_path(student_id: @student.id), alert: "Anda tidak memiliki relasi pembimbingan dengan mahasiswa ini."
      return
    end

    item = CompetencyItem.find(params[:competency_item_id])
    decision = EntrustmentDecision.decide!(student: @student, competency_item: item, level: params[:level].to_i,
                                           justification: params[:justification].to_s.strip, decided_by: current_user)
    Notification.notify!(recipient: @student, sender: current_user, notifiable: decision,
                         title: "Tingkat entrustment #{item.title} diperbarui", message: "Level #{decision.level} — #{decision.level_label}")
    redirect_to entrustment_decisions_path(student_id: @student.id), notice: "Penilaian #{item.title} tersimpan (level #{decision.level})."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to entrustment_decisions_path(student_id: @student.id), alert: e.record.errors.full_messages.to_sentence
  end

  private

  # Mahasiswa hanya peta miliknya; pengajar boleh membuka mahasiswa lain.
  def set_student
    if params[:student_id].present? && current_user.instructor?
      @student = User.find(params[:student_id])
    else
      @student = current_user
    end
  end

  def can_decide?
    return false if @student == current_user
    return true if current_user.has_role?("admin")
    return false unless current_user.instructor?

    @student.tutorial_enrollments.active.exists?(tutor: current_user) ||
      @student.clinical_rotations.ongoing.exists?(preceptor: current_user) ||
      @student.supervised_by?(current_user)
  end
end
