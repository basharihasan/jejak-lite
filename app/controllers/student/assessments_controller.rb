# frozen_string_literal: true

# Rubric-based / Asesmen Saya (mahasiswa): event yang tersedia untuk saya
# (prodi & blok cocok, masih terbuka), percobaan saya, unggah dokumen +
# evaluasi diri, lihat nilai & umpan balik penguji.
class Student::AssessmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_instance, only: %i[show submit]

  def index
    # Event yang bisa didaftar hanya relevan untuk diri sendiri.
    @available_events = viewing_other_student? ? [] : AssessmentEvent.published.includes(:academic_period, :study_program).ordered
                                                                       .select { |e| e.visible_to?(current_user) && !e.importable? }
    @my_instances = viewed_student.assessment_instances.includes(assessment_event: %i[academic_period], examiner: []).recent
    @attempts_by_event = @my_instances.group_by(&:assessment_event_id)
  end

  def show
    @profile = AssessmentCohortProfile.new(@instance) if @instance.status == "scored"
    @osce_stations = @instance.osce_station_scores.includes(:examiner).to_a
  end

  def submit
    unless @instance.assessment_event.submission_open? && @instance.status != "scored"
      redirect_to student_assessment_path(@instance), alert: "Pengumpulan sudah ditutup atau percobaan ini sudah dinilai."
      return
    end

    if params[:document].blank? && params[:self_evaluation].blank? && @instance.document.blank?
      redirect_to student_assessment_path(@instance), alert: "Unggah dokumen atau isi evaluasi diri terlebih dahulu."
      return
    end

    @instance.submit!(document: params[:document], self_evaluation: params[:self_evaluation])
    notify_examiner
    redirect_to student_assessment_path(@instance), notice: "Berhasil dikumpulkan. Penguji akan menilai."
  end

  private

  # Percobaan mahasiswa lain hanya bisa DILIHAT (show); submit selalu milik sendiri.
  def set_instance
    owner = action_name == "show" ? viewed_student : current_user
    @instance = owner.assessment_instances.includes(:assessment_event, :examiner).find(params[:id])
  end

  def notify_examiner
    return if @instance.examiner.nil?

    Notification.notify!(
      recipient: @instance.examiner, sender: current_user, notifiable: @instance,
      title: "Ada pengumpulan #{@instance.type_label} menunggu penilaian",
      message: "#{current_user.full_name} — #{@instance.assessment_event.name}"
    )
  end
end
