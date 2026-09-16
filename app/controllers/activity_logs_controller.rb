# frozen_string_literal: true

class ActivityLogsController < ApplicationController
  before_action :authenticate_user!, except: %i[feed]
  before_action :set_activity_log, only: %i[show edit update destroy generate_patient_code verify]

  # scope=to_verify (pengajar saja): kegiatan siapa pun yang belum
  # diverifikasi, meniru tab "Perlu Diverifikasi" ClinicalCasesController.
  def index
    @scope = params[:scope] == "to_verify" && current_user.can_verify_clinical_cases? ? "to_verify" : "mine"
    @competency_item_id = params[:competency_item_id].presence

    base = @scope == "to_verify" ? ActivityLog.awaiting_verification.includes(:user) : current_user.activity_logs
    # Chip filter hanya untuk domain yang benar-benar punya kegiatan di tab ini.
    # Parameternya `domain_id`, bukan `domain`: `domain:` adalah opsi host di
    # URL helper Rails dan dibuang diam-diam dari tautan.
    @filter_domains = AcademicActivityDomain.where(id: base.select(:academic_activity_domain_id)).ordered
    @domain = @filter_domains.find { |domain| domain.id.to_s == params[:domain_id].to_s }

    scope = base.recent
    scope = scope.in_domain(@domain.id) if @domain
    scope = scope.tagged_with(@competency_item_id) if @competency_item_id
    @activity_logs_by_date = scope.with_taxonomy.includes(:competency_items).group_by(&:activity_date)
    @all_competency_items = CompetencyItem.order(:position)
  end

  def show
    authorize @activity_log
  end

  def verify
    authorize @activity_log
    @activity_log.verify!(by: current_user)
    redirect_to @activity_log, notice: "Kegiatan diverifikasi."
  end

  def new
    now = Time.current.change(sec: 0)
    @activity_log = current_user.activity_logs.build(started_at: now, activity_date: now.to_date)
    load_form_collections
  end

  def create
    @activity_log = current_user.activity_logs.build(activity_log_params)
    @activity_log.require_form_fields = true
    @activity_log.evidence_files.attach(new_evidence_files) if new_evidence_files.any?

    if @activity_log.save
      redirect_to @activity_log, notice: "Kegiatan berhasil dicatat."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @activity_log
    # Kegiatan lama hanya punya tanggal: isi awal jam 08.00 di hari yang sama
    # supaya isian Waktu Mulai (wajib) tidak mengosong.
    @activity_log.started_at ||= @activity_log.activity_date&.in_time_zone&.change(hour: 8)
    load_form_collections
  end

  def update
    authorize @activity_log
    @activity_log.require_form_fields = true
    if @activity_log.update(activity_log_params)
      @activity_log.evidence_files.attach(new_evidence_files) if new_evidence_files.any?
      redirect_to @activity_log, notice: "Kegiatan berhasil diperbarui."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @activity_log
    @activity_log.destroy
    redirect_to activity_logs_path, notice: "Kegiatan dihapus.", status: :see_other
  end

  def generate_patient_code
    authorize @activity_log, :update?
    @activity_log.ensure_patient_code!
    redirect_to @activity_log, notice: "Kode pasien dibuat."
  end

  # Kalender bulanan sederhana (grid HTML, tanpa library JS) — bisa navigasi
  # bulan lewat query param ?bulan=YYYY-MM.
  def calendar
    @month = parse_month(params[:bulan]) || Date.current.beginning_of_month
    @logs_by_day = current_user.activity_logs.in_month(@month).recent.with_taxonomy
                               .includes(:competency_items).group_by(&:activity_date)
  end

  # Feed iCal publik-tapi-rahasia: URL-nya sendiri yang jadi kredensial
  # (token acak 24-byte), jadi tidak perlu login supaya aplikasi kalender
  # eksternal (Google Calendar dsb) bisa subscribe langsung.
  def feed
    user = User.find_by(calendar_feed_token: params[:token])
    return head :not_found if user.nil?

    logs = user.activity_logs.with_taxonomy.order(:activity_date)
    render plain: build_ics(user, logs), content_type: "text/calendar"
  end

  def reset_feed_token
    current_user.update!(calendar_feed_token: SecureRandom.urlsafe_base64(24))
    redirect_to activity_logs_calendar_path, notice: "Tautan feed kalender diperbarui — tautan lama tidak berlaku lagi."
  end

  private

  def set_activity_log
    @activity_log = ActivityLog.find(params[:id])
  end

  def activity_log_params
    permitted = params.require(:activity_log).permit(
      :title, :academic_activity_domain_id, :academic_activity_subdomain_id, :academic_activity_template_id,
      :started_at, :ended_at, :description, :reflection, :participant_count, :location, :delivery_mode,
      :academic_period_id, :clinical_rotation_id, :evidence_url, :document_url,
      competency_item_ids: []
    )
    permitted[:competency_item_ids] = permitted[:competency_item_ids].reject(&:blank?) if permitted[:competency_item_ids]
    permitted
  end

  # Lampiran baru DITAMBAHKAN lewat attach, bukan di-assign: di Rails 8
  # assign menggantikan seluruh lampiran, dan isian kosong dari input
  # `multiple` (hidden field bawaan) malah menghapus semuanya saat disunting.
  def new_evidence_files
    @new_evidence_files ||= Array(params.dig(:activity_log, :evidence_files)).select do |file|
      file.respond_to?(:original_filename)
    end
  end

  def load_form_collections
    @all_competency_items = CompetencyItem.order(:position)
    @domains = AcademicActivityDomain.active.ordered
                                     .includes(academic_activity_subdomains: :academic_activity_templates).to_a
    # Domain tersimpan yang sudah dinonaktifkan tetap ditampilkan supaya tidak
    # ikut terhapus saat kegiatan lama disunting.
    stored = @activity_log.academic_activity_domain
    @domains.unshift(stored) if stored && @domains.none? { |domain| domain.id == stored.id }
    @academic_periods = AcademicPeriod.ordered
    @clinical_rotations = @activity_log.user.clinical_rotations.includes(:academic_period).order(start_date: :desc)
  end

  def parse_month(value)
    Date.parse("#{value}-01") if value.present?
  rescue ArgumentError
    nil
  end

  def build_ics(user, logs)
    lines = [ "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//JEJAK Essential//Logbook//ID", "CALSCALE:GREGORIAN" ]
    logs.each do |log|
      lines.concat([
        "BEGIN:VEVENT",
        "UID:activity-log-#{log.id}@jejaklite",
        "DTSTAMP:#{log.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}",
        "DTSTART;VALUE=DATE:#{log.activity_date.strftime('%Y%m%d')}",
        "SUMMARY:#{ics_escape(log.title)}",
        "DESCRIPTION:#{ics_escape([ log.domain_label, log.taxonomy_detail ].compact.join(' - '))}",
        "END:VEVENT"
      ])
    end
    lines << "END:VCALENDAR"
    lines.join("\r\n")
  end

  def ics_escape(text)
    text.to_s.gsub(",", "\\,").gsub(";", "\\;")
  end
end
