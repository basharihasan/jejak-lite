# frozen_string_literal: true

# Konfigurasi → Kelola Ujian CBT — padanan /admin/cbt_exams jejak.pro: daftar
# ujian CBT & Progress Test (hasil impor maupun buatan admin) beserta jumlah
# peserta, ubah judul/tanggal di tempat, dan pintu ke pemetaan dimensi →
# ranah kompetensi (tab Dimensi event).
#
# Beda dengan jejak.pro: ujian yang sudah bernilai TIDAK dihapus dari sini —
# aturan yang sama dengan Assessment Events. Impor yang keliru dibatalkan
# lewat rollback di Riwayat Impor.
class Admin::CbtExamsController < Admin::BaseController
  before_action :set_exam, only: %i[edit update destroy]

  def index
    @exams = AssessmentEvent.cbt_exams.includes(:academic_period, :study_program)
                            .left_joins(:assessment_instances).group("assessment_events.id")
                            .select("assessment_events.*, COUNT(assessment_instances.id) AS participants_count")
                            .order(Arel.sql("assessment_events.exam_date DESC NULLS LAST, assessment_events.created_at DESC"))
    @exams = @exams.where("assessment_events.name ILIKE ?", "%#{AssessmentEvent.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @exams = @exams.page(params[:page]).per(20)
    @mapping = AssessmentDimension.where(assessment_event_id: @exams.map(&:id)).reorder(nil).group(:assessment_event_id)
                                  .pluck(:assessment_event_id, Arel.sql("COUNT(*)"), Arel.sql("COUNT(competency_item_id)"))
                                  .to_h { |id, total, mapped| [ id, [ mapped, total ] ] }
  end

  # Sunting di tempat (Turbo Frame) — ?field=name atau ?field=exam_date.
  def edit
    @field = params[:field] == "exam_date" ? "exam_date" : "name"
  end

  def update
    previous_date = @exam.exam_date
    if @exam.update(exam_params)
      shift_imported_dates!(previous_date)
      redirect_to admin_cbt_exams_path(q: params[:q].presence), notice: "Ujian #{@exam.name} diperbarui."
    else
      redirect_to admin_cbt_exams_path, alert: @exam.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @exam.assessment_instances.scored.exists?
      redirect_to admin_cbt_exams_path,
                  alert: "#{@exam.name} sudah punya nilai, jadi tidak dapat dihapus. Batalkan lewat rollback di Riwayat Impor, atau tutup event-nya."
      return
    end

    @exam.destroy
    redirect_to admin_cbt_exams_path, notice: "Ujian #{@exam.name} dihapus.", status: :see_other
  end

  private

  def set_exam
    @exam = AssessmentEvent.cbt_exams.find(params[:id])
  end

  def exam_params
    params.require(:assessment_event).permit(:name, :exam_date)
  end

  # Tanggal ujian dikoreksi → nilai hasil impor yang tercatat di tanggal lama
  # ikut pindah, supaya grafik tren & Evaluasi Akademik memakai tanggal yang
  # benar (padanan rebuild ADP jejak.pro).
  def shift_imported_dates!(previous_date)
    return if @exam.exam_date.blank? || previous_date == @exam.exam_date

    scope = @exam.assessment_instances.where(source: "import")
    scope = scope.where(scored_at: previous_date.in_time_zone.all_day) if previous_date
    scope.update_all(scored_at: @exam.exam_date.in_time_zone, updated_at: Time.current)
  end
end
