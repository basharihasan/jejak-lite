# frozen_string_literal: true

# Jadwal DOPS & Mini-CEX — admin (semua prodi) dan kaprodi. Kaprodi terikat ke
# prodi binaannya (users.study_program_id): hanya jadwal mahasiswa prodinya
# yang tampil, dan mahasiswa/rotasi prodi lain ditolak server-side.
class Admin::EvaluationSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_schedule, only: %i[edit update destroy]

  def index
    @schedules = schedule_scope.includes(:student, :evaluator, :clinical_rotation).ordered.page(params[:page]).per(50)
  end

  def new
    @schedule = EvaluationSchedule.new(kind: "mini_cex", scheduled_at: 1.day.from_now.change(hour: 9))
    load_collections
  end

  def create
    @schedule = EvaluationSchedule.new(schedule_params)
    if within_study_program?(@schedule) && @schedule.save
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
    @schedule.assign_attributes(schedule_params)
    if within_study_program?(@schedule) && @schedule.save
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
    unless current_user.has_role?("admin") || current_user.has_role?("kaprodi")
      return redirect_to dashboard_path, alert: "Halaman ini khusus admin/kaprodi."
    end
    return unless current_user.study_program_bound? && current_user.study_program_id.nil?

    redirect_to dashboard_path,
                alert: "Akun kaprodi Anda belum terhubung ke Program Studi — minta admin mengisinya di Konfigurasi → Pengguna."
  end

  def student_scope
    students = User.joins(:roles).where(roles: { code: "mahasiswa" }).distinct
    current_user.study_program_bound? ? students.where(study_program_id: current_user.study_program_id) : students
  end

  def schedule_scope
    return EvaluationSchedule.all unless current_user.study_program_bound?

    EvaluationSchedule.where(student_id: student_scope.select(:id))
  end

  def set_schedule
    @schedule = schedule_scope.find(params[:id])
  end

  # Mahasiswa (dan rotasinya) harus dalam cakupan prodi akun ini.
  def within_study_program?(schedule)
    return true unless current_user.study_program_bound?

    schedule.errors.add(:student, "di luar program studi binaan Anda") if schedule.student_id && !student_scope.exists?(schedule.student_id)
    rotation = schedule.clinical_rotation
    schedule.errors.add(:clinical_rotation, "bukan rotasi mahasiswa prodi Anda") if rotation && !student_scope.exists?(rotation.user_id)
    schedule.errors.none?
  end

  def load_collections
    @students = student_scope.order(:full_name)
    @evaluators = User.joins(:roles).where(roles: { code: %w[dosen preseptor] }).distinct.order(:full_name)
    @rotations = ClinicalRotation.where(user_id: student_scope.select(:id)).includes(:user).order(start_date: :desc).limit(200)
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
