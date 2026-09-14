# frozen_string_literal: true

class Admin::EvaluationSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_schedule, only: %i[edit update destroy]

  def index
    @schedules = EvaluationSchedule.includes(:student, :evaluator, :clinical_rotation).ordered.page(params[:page]).per(50)
  end

  def new
    @schedule = EvaluationSchedule.new(kind: "mini_cex", scheduled_at: 1.day.from_now.change(hour: 9))
    load_collections
  end

  def create
    @schedule = EvaluationSchedule.new(schedule_params)
    if @schedule.save
      notify_parties
      redirect_to admin_evaluation_schedules_path, notice: "Jadwal #{@schedule.kind_label} dibuat."
    else
      load_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_collections
  end

  def update
    if @schedule.update(schedule_params)
      redirect_to admin_evaluation_schedules_path, notice: "Jadwal diperbarui."
    else
      load_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule.destroy
    redirect_to admin_evaluation_schedules_path, notice: "Jadwal dihapus.", status: :see_other
  end

  private

  def require_admin!
    return if current_user.has_role?("admin") || current_user.has_role?("kaprodi")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin/kaprodi."
  end

  def set_schedule
    @schedule = EvaluationSchedule.find(params[:id])
  end

  def load_collections
    @students = User.joins(:roles).where(roles: { code: "mahasiswa" }).distinct.order(:full_name)
    @evaluators = User.joins(:roles).where(roles: { code: %w[dosen preseptor] }).distinct.order(:full_name)
    @rotations = ClinicalRotation.includes(:user).order(start_date: :desc).limit(200)
  end

  def schedule_params
    params.require(:evaluation_schedule).permit(:kind, :student_id, :evaluator_id, :clinical_rotation_id, :scheduled_at, :topic, :status, :notes)
  end

  def notify_parties
    [ @schedule.student, @schedule.evaluator ].compact.each do |u|
      Notification.notify!(recipient: u, notifiable: @schedule,
                           title: "Jadwal #{@schedule.kind_label} #{I18n.l(@schedule.scheduled_at, format: :short)}",
                           message: @schedule.topic.presence || "#{@schedule.student.full_name} · #{@schedule.evaluator&.full_name}")
    end
  end
end
