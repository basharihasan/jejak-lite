# frozen_string_literal: true

require "csv"

# Konfigurasi → Assessment Events: buat/terbitkan event, daftarkan percobaan,
# tugaskan penguji, isi nilai manual, dan impor CSV berpemetaan kolom.
class Admin::AssessmentEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_event, only: %i[show edit update destroy import import_template import_preview import_create add_instance]
  before_action :require_importable_event!, only: %i[import import_template import_preview import_create]

  def index
    @events = AssessmentEvent.includes(:academic_period, :study_program).ordered.page(params[:page]).per(30)
  end

  def show
    @tab = params[:tab] == "dimensi" ? "dimensi" : "peserta"
    @dimensions = @event.assessment_dimensions.includes(:competency_item, :assessment_dimension_scores)
    @competency_items = competency_item_choices
    @instances = @event.assessment_instances.includes(:student, :examiner, assessment_dimension_scores: :assessment_dimension)
                       .joins(:student).order("users.full_name", :attempt_number)
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

  # Kolom templat impor nilai. Header sengaja memakai nama yang dikenali
  # suggest_mapping / suggest_dimension_mapping supaya langkah pemetaan
  # terisi otomatis. Kolom nama & NPM hanya penanda bagi pengisi.
  INFO_HEADERS = %w[nama_mahasiswa npm].freeze

  # GET /admin/assessment_events/:id/import_template.csv — berisi daftar
  # mahasiswa (yang sudah punya nilai di event ini, atau mahasiswa prodi
  # event) dengan kolom nilai kosong; baris yang dibiarkan kosong dilewati
  # saat impor.
  def import_template
    dimensions = @event.assessment_dimensions.to_a
    headers = %w[email] + INFO_HEADERS
    headers << "skor" if dimensions.empty?
    headers << "percobaan" if @event.allow_multiple_attempts?
    headers << "tanggal"
    headers += dimensions.map(&:name)

    # Tanggal diisi tanggal ujian event sebagai bawaan; ubah per baris untuk
    # ujian susulan/remedial. Kolom nilai tetap kosong.
    date_index = headers.index("tanggal")
    exam_date = @event.exam_date&.iso8601
    build_row = lambda do |email, name, npm|
      row = [ email, name, npm ] + Array.new(headers.size - 3)
      row[date_index] = exam_date
      row
    end

    students = template_students
    csv = CSV.generate do |rows|
      rows << headers
      if students.any?
        students.each { |s| rows << build_row.call(s.email, s.full_name, s.identifier_number) }
      else
        rows << build_row.call("mahasiswa@kampus.ac.id", "Contoh Mahasiswa", "2206000123")
      end
    end
    # BOM di depan supaya Excel membaca UTF-8 (nama beraksen tidak rusak);
    # importer sudah membuangnya lagi saat unggah.
    send_data "\uFEFF#{csv}", filename: "template_nilai_#{@event.name.parameterize}.csv", type: "text/csv; charset=utf-8"
  end

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
    @dimensions = @event.assessment_dimensions.includes(:competency_item)
    @suggested_dimensions = suggest_dimension_mapping(@headers)
    render :import_preview
  end

  def import_create
    create_dimensions_from_columns! if params[:create_dimensions].present?

    @result = AssessmentScoreImporter.new(
      event: @event,
      csv_text: params[:csv_text],
      mapping: params.fetch(:mapping, {}).permit(:email, :score, :max_score, :attempt, :date).to_h,
      dimension_mapping: params.fetch(:dimension_mapping, {}).permit!.to_h
    ).call
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

  # Pilihan ranah kompetensi untuk pemetaan dimensi — ranah beserta
  # sub-kompetensinya, ditampilkan bertingkat.
  def competency_item_choices
    CompetencyItem.includes(:competency_framework, :children).where(parent_id: nil).order(:position).flat_map do |domain|
      [ [ domain.title, domain.id ] ] + domain.children.map { |child| [ "— #{child.title}", child.id ] }
    end
  end

  # Kolom yang belum dipetakan dapat langsung dijadikan dimensi baru, supaya
  # admin tidak perlu mengetik ulang 12 nama station OSCE satu per satu.
  def create_dimensions_from_columns!
    reserved = params.fetch(:mapping, {}).values.map(&:to_s)
    Array(params[:create_dimensions]).reject(&:blank?).each do |column|
      next if reserved.include?(column)
      next if @event.assessment_dimensions.where("LOWER(name) = ?", column.downcase).exists?

      @event.assessment_dimensions.create!(name: column, max_score: @event.max_score)
    end
    @event.reload
  end

  # Kolom yang namanya sama dengan nama/kode dimensi langsung dicocokkan.
  def suggest_dimension_mapping(headers)
    normalized = headers.index_by { |h| h.to_s.strip.downcase }
    @event.assessment_dimensions.each_with_object({}) do |dimension, acc|
      match = normalized[dimension.name.to_s.downcase] || normalized[dimension.code.to_s.downcase]
      acc[dimension.id] = match if match
    end
  end

  def template_students
    registered = User.where(id: @event.assessment_instances.select(:student_id))
    return registered.order(:full_name) if registered.exists?
    return User.none if @event.study_program_id.blank?

    User.joins(:roles).where(roles: { code: "mahasiswa" }, study_program_id: @event.study_program_id).distinct.order(:full_name)
  end

  # Tebakan awal pemetaan dari nama header (admin tetap bisa mengubah).
  def suggest_mapping(headers)
    find = ->(*cands) { headers.find { |h| cands.include?(h.to_s.strip.downcase.tr(" ", "_")) } }
    {
      "email" => find.call("email", "e-mail", "surel", "email_mahasiswa"),
      "score" => find.call("score", "skor", "nilai", "total", "nilai_akhir"),
      "max_score" => find.call("max_score", "max", "nilai_maks", "skor_maks", "maksimum"),
      "attempt" => find.call("attempt", "percobaan", "attempt_number", "ujian_ke"),
      "date" => find.call("tanggal", "tanggal_ujian", "tgl", "date", "exam_date")
    }
  end
end
