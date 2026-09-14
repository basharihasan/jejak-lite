# frozen_string_literal: true

# Konfigurasi → Assessment Events: buat/terbitkan event, daftarkan percobaan,
# tugaskan penguji, isi nilai manual, dan impor CSV berpemetaan kolom.
class Admin::AssessmentEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_event, only: %i[show edit update destroy import import_preview import_create add_instance]
  before_action :require_importable_event!, only: %i[import import_preview import_create]

  def index
    @events = AssessmentEvent.includes(:academic_period, :study_program).ordered.page(params[:page]).per(30)
  end

  def show
    @instances = @event.assessment_instances.includes(:student, :examiner).joins(:student).order("users.full_name", :attempt_number)
    @students = User.joins(:roles).where(roles: { code: "mahasiswa" }).distinct.order(:full_name)
    @examiners = User.joins(:roles).where(roles: { code: %w[dosen preseptor kaprodi] }).distinct.order(:full_name)
  end

  def new
    @event = AssessmentEvent.new(academic_period: AcademicPeriod.ordered.first, status: "draft", max_score: 100)
    load_collections
  end

  def create
    @event = AssessmentEvent.new(event_params.merge(created_by: current_user))
    if @event.save
      redirect_to admin_assessment_event_path(@event), notice: "Assessment Event dibuat."
    else
      load_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_collections
  end

  def update
    previous_max = @event.max_score
    if @event.update(event_params)
      sync_max_score!(previous_max)
      redirect_to admin_assessment_event_path(@event), notice: "Assessment Event diperbarui."
    else
      load_collections
      render :edit, status: :unprocessable_entity
    end
  end

  # Menghapus event membuang nilai yang sudah keluar — termasuk yang sudah
  # dipakai Assessment Matrix & kurva kohort. Event bernilai ditutup, bukan dihapus.
  def destroy
    if @event.assessment_instances.scored.exists?
      redirect_to admin_assessment_event_path(@event),
                  alert: "Event ini sudah punya nilai, jadi tidak dapat dihapus. Ubah statusnya menjadi Ditutup bila tidak dipakai lagi."
      return
    end

    @event.destroy
    redirect_to admin_assessment_events_path, notice: "Assessment Event dihapus.", status: :see_other
  end

  # Daftarkan percobaan (baru) untuk seorang mahasiswa — juga dipakai untuk
  # ujian ulang pada event berpercobaan-ulang.
  def add_instance
    student = User.find(params[:student_id])
    attempt = @event.allow_multiple_attempts? ? AssessmentInstance.next_attempt_number(@event, student) : 1
    instance = AssessmentInstance.find_or_initialize_by(assessment_event: @event, student: student, attempt_number: attempt)
    if instance.new_record?
      instance.max_score = @event.max_score
      instance.examiner_id = params[:examiner_id].presence
      instance.scheduled_at = params[:scheduled_at].presence
      instance.save!
      redirect_to admin_assessment_event_path(@event), notice: "#{student.full_name} didaftarkan (percobaan ke-#{attempt})."
    else
      redirect_to admin_assessment_event_path(@event), alert: "#{student.full_name} sudah terdaftar; event ini tidak mengizinkan percobaan berulang."
    end
  end

  # ── Impor CSV 3 langkah: unggah → petakan kolom → jalankan ──
  def import; end

  def import_preview
    file = params[:file]
    if file.blank?
      redirect_to import_admin_assessment_event_path(@event), alert: "Pilih berkas CSV terlebih dahulu."
      return
    end

    @csv_text = file.read.force_encoding("UTF-8").delete_prefix("﻿")
    @headers, @sample_rows = AssessmentScoreImporter.parse_headers(@csv_text)
    if @headers.empty?
      redirect_to import_admin_assessment_event_path(@event), alert: "Berkas tidak punya baris header yang bisa dibaca."
      return
    end

    @suggested = suggest_mapping(@headers)
    render :import_preview
  end

  def import_create
    @result = AssessmentScoreImporter.new(event: @event, csv_text: params[:csv_text], mapping: params.fetch(:mapping, {}).permit(:email, :score, :max_score, :attempt).to_h).call
    render :import_result
  end

  private

  def require_admin!
    return if current_user.has_role?("admin")

    redirect_to dashboard_path, alert: "Halaman ini khusus admin."
  end

  def set_event
    @event = AssessmentEvent.find(params[:id])
  end

  # Impor CSV hanya masuk akal untuk ujian tulis/praktik. Sebelumnya tombolnya
  # memang disembunyikan, tetapi alamatnya tetap dapat dibuka langsung.
  def require_importable_event!
    return if @event.importable?

    redirect_to admin_assessment_event_path(@event),
                alert: "Impor CSV hanya untuk ujian tulis/praktik. #{@event.type_label} dinilai lewat lembar penguji atau dari kasus."
  end

  # Nilai maksimum event berubah → percobaan yang BELUM dinilai ikut berubah.
  # Yang sudah dinilai sengaja dibiarkan: mengubah penyebut nilai yang sudah
  # keluar akan menggeser persentase mahasiswa tanpa ada yang tahu.
  def sync_max_score!(previous_max)
    return if previous_max == @event.max_score

    @event.assessment_instances.where.not(status: "scored").update_all(max_score: @event.max_score)
  end

  def load_collections
    @academic_periods = AcademicPeriod.ordered
    @study_programs = StudyProgram.ordered
    @form_templates = AssessmentFormTemplate.where(is_active: true).order(:name)
  end

  def event_params
    params.require(:assessment_event).permit(
      :name, :assessment_type, :academic_period_id, :study_program_id, :block_name, :exam_date, :status,
      :max_score, :allow_multiple_attempts, :submission_close_at, :assessment_form_template_id, :description
    )
  end

  # Tebakan awal pemetaan dari nama header (admin tetap bisa mengubah).
  def suggest_mapping(headers)
    find = ->(*cands) { headers.find { |h| cands.include?(h.to_s.strip.downcase.tr(" ", "_")) } }
    {
      "email" => find.call("email", "e-mail", "surel", "email_mahasiswa"),
      "score" => find.call("score", "skor", "nilai", "total", "nilai_akhir"),
      "max_score" => find.call("max_score", "max", "nilai_maks", "skor_maks", "maksimum"),
      "attempt" => find.call("attempt", "percobaan", "attempt_number", "ujian_ke")
    }
  end
end
