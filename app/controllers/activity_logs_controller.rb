# frozen_string_literal: true

class ActivityLogsController < ApplicationController
  before_action :authenticate_user!, except: %i[feed]
  before_action :set_activity_log, only: %i[show edit update destroy generate_patient_code]

  def index
    @category = params[:category] if ActivityLog::CATEGORIES.key?(params[:category])
    scope = current_user.activity_logs.recent
    scope = scope.where(category: @category) if @category
    @activity_logs = scope.page(params[:page])
  end

  def show
  end

  def new
    @activity_log = current_user.activity_logs.build(activity_date: Date.current)
  end

  def create
    @activity_log = current_user.activity_logs.build(activity_log_params)

    if @activity_log.save
      redirect_to @activity_log, notice: "Kegiatan berhasil dicatat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity_log.update(activity_log_params)
      redirect_to @activity_log, notice: "Kegiatan berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity_log.destroy
    redirect_to activity_logs_path, notice: "Kegiatan dihapus.", status: :see_other
  end

  def generate_patient_code
    @activity_log.ensure_patient_code!
    redirect_to @activity_log, notice: "Kode pasien dibuat."
  end

  # Kalender bulanan sederhana (grid HTML, tanpa library JS) — bisa navigasi
  # bulan lewat query param ?bulan=YYYY-MM.
  def calendar
    @month = parse_month(params[:bulan]) || Date.current.beginning_of_month
    @logs_by_day = current_user.activity_logs.in_month(@month).group_by(&:activity_date)
  end

  # Feed iCal publik-tapi-rahasia: URL-nya sendiri yang jadi kredensial
  # (token acak 24-byte), jadi tidak perlu login supaya aplikasi kalender
  # eksternal (Google Calendar dsb) bisa subscribe langsung.
  def feed
    user = User.find_by(calendar_feed_token: params[:token])
    return head :not_found if user.nil?

    logs = user.activity_logs.order(:activity_date)
    render plain: build_ics(user, logs), content_type: "text/calendar"
  end

  def reset_feed_token
    current_user.update!(calendar_feed_token: SecureRandom.urlsafe_base64(24))
    redirect_to activity_logs_calendar_path, notice: "Tautan feed kalender diperbarui — tautan lama tidak berlaku lagi."
  end

  private

  def set_activity_log
    @activity_log = current_user.activity_logs.find(params[:id])
  end

  def activity_log_params
    params.require(:activity_log).permit(
      :title, :category, :activity_type, :activity_date, :description, :reflection,
      :participant_count, evidence_files: []
    )
  end

  def parse_month(value)
    Date.parse("#{value}-01") if value.present?
  rescue ArgumentError
    nil
  end

  def build_ics(user, logs)
    lines = [ "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Jejak Lite//Logbook//ID", "CALSCALE:GREGORIAN" ]
    logs.each do |log|
      lines.concat([
        "BEGIN:VEVENT",
        "UID:activity-log-#{log.id}@jejaklite",
        "DTSTAMP:#{log.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}",
        "DTSTART;VALUE=DATE:#{log.activity_date.strftime('%Y%m%d')}",
        "SUMMARY:#{ics_escape(log.title)}",
        "DESCRIPTION:#{ics_escape("#{log.category_label} - #{log.activity_type}")}",
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
