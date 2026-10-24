# frozen_string_literal: true

# Beranda — mengikuti pola beranda jejak.pro, dipersempit ke fitur yang ADA di
# JEJAK Essential (tanpa EWS/Tutor Note, refleksi ber-review, P-Max, hibah).
#
#   - Semua peran: sapaan + Agenda Mendatang (7 hari).
#   - Mahasiswa: peringatan kasus draft / diminta perbaikan, pengingat
#     pencatatan kasus, fokus rotasi/blok berjalan, Pusat Asesmen & Capaian.
#   - Dosen/preseptor/kaprodi/admin: strip "Ringkasan Hari Ini", panel
#     "Perlu Tindakan Anda", dan "Mahasiswa Bimbingan Anda" per peran.
#
# Bercabang menurut PERAN AKTIF (sama dengan sidebar), bukan gabungan semua
# peran, supaya akun multi-peran melihat beranda satu peran pada satu waktu.
# Semua angka dihitung langsung dari model yang sudah ada — tidak ada service
# atau tabel baru khusus beranda.
class DashboardController < ApplicationController
  before_action :authenticate_user!

  FACULTY_ROLE_CODES = %w[dosen preseptor kaprodi admin].freeze

  # Pengingat pencatatan kasus: mahasiswa yang sedang berotasi klinik dan
  # tidak mencatat kasus baru dalam N hari kalender terakhir (meniru
  # DashboardController#load_case_logging_reminder jejak.pro).
  CASE_LOGGING_GAP_DAYS = 2

  AGENDA_HORIZON_DAYS = 7
  # Agenda ditarik sampai 8 butir walau panel hanya menampilkan 5, supaya
  # panel bisa menulis "+N agenda lainnya" alih-alih memotong diam-diam.
  AGENDA_LIMIT = 8

  # Pengganti EWS jejak.pro untuk "Mahasiswa Perlu Perhatian": sinyal yang
  # memang tercatat di Essential — rekomendasi remediasi saat verifikasi
  # kasus dan rata-rata DOPS/Mini-CEX di bawah harapan (< 4 pada skala 1-9,
  # sama dengan pita merah score_band_classes) — dalam jendela 30 hari.
  ATTENTION_WINDOW_DAYS = 30
  LOW_SCORE_THRESHOLD = 4
  # Bagi preseptor: mahasiswa rotasinya yang seminggu tidak mencatat kasus.
  # Lebih longgar dari pengingat mahasiswa (2 hari) agar panel tidak penuh.
  ATTENTION_LOGGING_GAP_DAYS = 7

  ALERT_LIST_LIMIT = 3
  PENDING_CASE_LIST_LIMIT = 5

  # Satu butir "Agenda Mendatang" — bentuk seragam untuk semua sumber
  # (rotasi, tutorial, jadwal DOPS/Mini-CEX, ujian, tenggat tugas akhir,
  # kegiatan). Pemformatan tanggalnya di DashboardHelper.
  AgendaItem = Struct.new(
    :kind, :title, :person, :location, :starts_at, :ends_at,
    :all_day, :deadline, :status_label, :status_tone, :path,
    keyword_init: true
  ) do
    def multi_day?
      ends_at.present? && ends_at.to_date != starts_at.to_date
    end

    # Selisih hari kalender, bukan jam — acara besok pagi tetap "Besok".
    def days_away(from = Date.current)
      (starts_at.to_date - from).to_i
    end
  end

  def show
    @active_role = current_user.active_role || current_user.roles.first
    @active_code = @active_role&.code
    @dashboard_mode = if @active_code == "mahasiswa" then :student
    elsif FACULTY_ROLE_CODES.include?(@active_code) then :faculty
    end

    load_upcoming_agenda
    case @dashboard_mode
    when :student then load_student_dashboard
    when :faculty then load_faculty_dashboard
    end
  end

  private

  # ── Mahasiswa ─────────────────────────────────────────────────────────────

  def load_student_dashboard
    load_case_logging_reminder

    # Draft hanya terlihat oleh pemiliknya — preseptor belum menerimanya.
    drafts = current_user.clinical_cases.where(status: "draft")
    @draft_case_count = drafts.count
    @draft_cases = drafts.order(created_at: :desc).limit(ALERT_LIST_LIMIT) if @draft_case_count.positive?

    # Bola kembali di mahasiswa: preseptor meminta perbaikan.
    revisions = current_user.clinical_cases.where(status: "needs_revision")
    @revision_case_count = revisions.count
    @revision_cases = revisions.includes(:verified_by).order(updated_at: :desc).limit(ALERT_LIST_LIMIT) if @revision_case_count.positive?

    @ongoing_rotation = current_user.clinical_rotations.ongoing.includes(:preceptor).order(:end_date).first
    @upcoming_rotation = current_user.clinical_rotations.upcoming.first if @ongoing_rotation.nil?
    @active_tutorial = current_user.tutorial_enrollments.active.includes(:tutor).order(start_date: :desc).first

    cases = current_user.clinical_cases
    @student_stats = {
      activities_this_month: current_user.activity_logs.in_month(Date.current).count,
      cases_total: cases.count,
      cases_verified: cases.where(status: "verified").count,
      reflections: current_user.reflection_entries.count
    }
    @profile_completeness = current_user.profile_completeness
    @missing_profile_fields = current_user.missing_profile_fields

    @academic_flags = attention_reasons_for([ current_user.id ])[current_user.id]
    @pending_assessment_count = current_user.assessment_instances.awaiting_score.count
    load_own_competency_radar
  end

  # Dihitung per hari kalender (zona aplikasi), bukan jam bergulir, supaya
  # pengingat muncul di pergantian hari. Yang baru mulai rotasi dalam jendela
  # itu belum ditagih.
  def load_case_logging_reminder
    @case_logging_gap = nil
    since = (Date.current - (CASE_LOGGING_GAP_DAYS - 1)).beginning_of_day
    started = current_user.clinical_rotations.ongoing.minimum(:start_date)
    return if started.nil? || started >= since.to_date

    last_at = current_user.clinical_cases.maximum(:created_at)
    return if last_at.present? && last_at >= since

    @case_logging_gap = { last_at: last_at, days: last_at && (Date.current - last_at.to_date).to_i }
  end

  def load_own_competency_radar
    dops_scores = current_user.dops_evaluations_as_student.submitted
    @own_dops_radar = DopsEvaluation.avg_dimension_scores(dops_scores) if dops_scores.any?

    mini_cex_scores = current_user.mini_cex_evaluations_as_student.submitted
    @own_mini_cex_radar = MiniCexEvaluation.avg_dimension_scores(mini_cex_scores) if mini_cex_scores.any?
  end

  # ── Dosen / preseptor / kaprodi / admin ───────────────────────────────────

  def load_faculty_dashboard
    load_verification_queue
    load_grading_queue
    load_scheduled_evaluations
    load_mentees
    load_attention_students
    load_feedback_record

    @action_counts = {
      cases: @pending_case_count.to_i,
      activities: @pending_activity_count.to_i,
      grading: @pending_workplace_evaluations.size + @pending_examiner_instances.size,
      attention: @attention_students.size,
      schedules: @scheduled_evaluations.size
    }
    @action_total = @action_counts.values.sum
  end

  # Antrean yang SAMA dengan tab "Perlu Diverifikasi" Logbook Kasus/Kegiatan
  # (dan lencana sidebar), supaya angka di beranda = isi halaman tujuannya.
  # Kaprodi tanpa peran pengajar tidak memverifikasi, jadi tidak dihitung.
  def load_verification_queue
    @can_verify = current_user.can_verify_clinical_cases?
    return unless @can_verify

    case_queue = ClinicalCase.awaiting_verification_by(current_user)
    @pending_case_count = case_queue.count
    # Terlama menunggu didahulukan.
    @pending_cases = case_queue.includes(:user).order(:updated_at).limit(PENDING_CASE_LIST_LIMIT).to_a
    @pending_activity_count = ActivityLog.awaiting_verification_by(current_user).count
  end

  # "Perlu Dinilai": DOPS/Mini-CEX yang diminta mahasiswa atau masih draf
  # (sama dengan daftar di halaman Workplace Assessment), plus percobaan
  # asesmen yang sudah dikumpulkan mahasiswa dan ditugaskan kepada saya.
  def load_grading_queue
    @pending_workplace_evaluations = (
      DopsEvaluation.pending_for_evaluator.where(evaluator: current_user).includes(:student, :clinical_rotation).to_a +
      MiniCexEvaluation.pending_for_evaluator.where(evaluator: current_user).includes(:student, :clinical_rotation).to_a
    ).sort_by(&:evaluated_at)

    @pending_examiner_instances = AssessmentInstance.for_examiner(current_user).where(status: "submitted")
                                                    .includes(:student, :assessment_event).order(:submitted_at).to_a
  end

  # Jadwal DOPS/Mini-CEX dari prodi yang masih "Terjadwal" sampai akhir bulan
  # ini (termasuk yang sudah lewat tanggal tapi belum dikerjakan). Status
  # jadwal hanya diubah admin, jadi jadwal dianggap TUNAI begitu penilai ini
  # mengirim evaluasi sejenis untuk mahasiswa itu sejak awal bulan jadwalnya —
  # tanpa itu tugas yang sudah dikerjakan tetap menagih di beranda.
  # Tile-nya hanya untuk preseptor atau yang memang punya jadwal — dosen yang
  # tak pernah dijadwalkan tidak perlu tile "0 ✓ Beres" permanen.
  def load_scheduled_evaluations
    schedules = EvaluationSchedule.where(evaluator: current_user, status: "planned")
                                  .where(scheduled_at: ..Time.current.end_of_month)
                                  .includes(:student, :clinical_rotation).order(:scheduled_at).to_a
    student_ids = schedules.map(&:student_id).uniq
    done = { "dops" => DopsEvaluation, "mini_cex" => MiniCexEvaluation }.transform_values do |model|
      student_ids.empty? ? [] : model.submitted.where(evaluator: current_user, student_id: student_ids).pluck(:student_id, :evaluated_at)
    end

    @scheduled_evaluations = schedules.reject do |s|
      done.fetch(s.kind, []).any? { |sid, at| sid == s.student_id && at >= s.scheduled_at.to_date.beginning_of_month }
    end
    @show_schedule_tile = current_user.has_role?("preseptor") || @scheduled_evaluations.any?
  end

  # Mahasiswa bimbingan menurut peran pengajar terhadapnya — padanan modul
  # Preseptor/Tutor/Pembimbing Karya Akhir jejak.pro.
  def load_mentees
    @preceptor_rotations = ClinicalRotation.for_preceptor(current_user).ongoing.includes(:user).order(:end_date).to_a
    @tutor_enrollments = TutorialEnrollment.for_tutor(current_user).active.includes(:user)
                                           .order(:block_name, :group_name).to_a
    @supervised_projects = current_user.supervised_final_projects.where.not(status: "completed")
                                       .includes(:student, :final_project_milestones).order(:created_at).to_a

    @mentee_ids = (@preceptor_rotations.map(&:user_id) + @tutor_enrollments.map(&:user_id) +
                   @supervised_projects.map(&:student_id)).uniq
    @show_preceptor_panel = @active_code == "preseptor" || @preceptor_rotations.any?
  end

  # Populasi: mahasiswa bimbingan; kaprodi ditambah seluruh mahasiswa prodinya
  # (pemantau program, sama seperti bagian Program Studi di Dashboard Analitik).
  def load_attention_students
    population = @mentee_ids
    if @active_code == "kaprodi" && current_user.study_program_id
      population |= User.joins(:roles).where(roles: { code: "mahasiswa" }, study_program_id: current_user.study_program_id)
                        .distinct.pluck(:id)
    end

    gap_cutoff = Date.current - ATTENTION_LOGGING_GAP_DAYS
    gap_ids = @preceptor_rotations.select { |r| r.start_date <= gap_cutoff }.map(&:user_id).uniq

    reasons = attention_reasons_for(population, logging_gap_ids: gap_ids)
    users = User.where(id: reasons.keys).index_by(&:id)
    @attention_students = reasons.filter_map { |uid, rs| { user: users[uid], reasons: rs } if users[uid] }
                                 .sort_by { |s| [ -s[:reasons].size, s[:user].full_name ] }
  end

  # { user_id => [ { label:, severity: (:high | :medium), detail: } ] } — hanya
  # mahasiswa yang punya sinyal.
  def attention_reasons_for(student_ids, logging_gap_ids: [])
    reasons = Hash.new { |hash, key| hash[key] = [] }
    return reasons if student_ids.empty?

    since = ATTENTION_WINDOW_DAYS.days.ago
    ClinicalCase.where(user_id: student_ids, status: "verified", recommend_remediation: true, verified_at: since..)
                .group(:user_id).count.each do |uid, count|
      reasons[uid] << { label: "Rekomendasi remediasi", severity: :high, detail: "#{count} kasus terverifikasi dalam #{ATTENTION_WINDOW_DAYS} hari terakhir" }
    end

    { DopsEvaluation => "DOPS", MiniCexEvaluation => "Mini-CEX" }.each do |model, label|
      model.submitted.where(student_id: student_ids, evaluated_at: since.to_date..).group_by(&:student_id).each do |uid, evaluations|
        scores = evaluations.filter_map(&:average_score)
        next if scores.empty?

        avg = (scores.sum / scores.size).round(1)
        next unless avg < LOW_SCORE_THRESHOLD

        reasons[uid] << { label: "Skor #{label} di bawah harapan", severity: :medium, detail: "rata-rata #{avg} dari #{scores.size} penilaian (#{ATTENTION_WINDOW_DAYS} hari terakhir)" }
      end
    end

    if logging_gap_ids.any?
      recent = ClinicalCase.where(user_id: logging_gap_ids, created_at: ATTENTION_LOGGING_GAP_DAYS.days.ago..).distinct.pluck(:user_id)
      (logging_gap_ids - recent).each do |uid|
        reasons[uid] << { label: "Logbook kasus sepi", severity: :medium, detail: "tidak ada kasus baru dalam #{ATTENTION_LOGGING_GAP_DAYS} hari selama rotasi Anda" }
      end
    end

    reasons
  end

  # Rekam umpan balik naratif yang pernah ditulis pengajar ini (DOPS, Mini-CEX,
  # lembar penguji) — padanan "Rekam Umpan Balik Anda" jejak.pro.
  def load_feedback_record
    narratives = current_user.dops_evaluations_as_evaluator.submitted.pluck(:overall_feedback) +
                 current_user.mini_cex_evaluations_as_evaluator.submitted.pluck(:overall_feedback) +
                 AssessmentInstance.for_examiner(current_user).scored.pluck(:feedback_keep, :feedback_improve)
                                   .map { |keep, improve| [ keep, improve ].compact_blank.join(" ") }
    narratives = narratives.compact_blank

    @feedback_count = narratives.size
    @feedback_avg_words = narratives.empty? ? 0 : (narratives.sum { |n| n.split.size }.to_f / narratives.size).round
  end

  # ── Agenda Mendatang (semua peran) ────────────────────────────────────────

  def load_upcoming_agenda
    window = Time.current..(Time.current + AGENDA_HORIZON_DAYS.days)
    dates = Date.current..(Date.current + AGENDA_HORIZON_DAYS)

    @upcoming_agenda = [
      activity_log_agenda(window),
      rotation_agenda(dates),
      tutorial_agenda(dates),
      evaluation_schedule_agenda(window),
      assessment_agenda(window, dates),
      final_project_agenda(dates)
    ].flatten.sort_by(&:starts_at).first(AGENDA_LIMIT)
  end

  # Kegiatan milik sendiri yang dijadwalkan ke depan (Kalender Kegiatan).
  def activity_log_agenda(window)
    current_user.activity_logs.where(started_at: window).with_taxonomy.order(:started_at).limit(AGENDA_LIMIT).map do |log|
      AgendaItem.new(kind: :kegiatan, title: log.title, location: log.location.presence,
                     starts_at: log.started_at, ends_at: log.ended_at,
                     status_label: log.kind_label || log.domain_label, status_tone: :slate, path: activity_log_path(log))
    end
  end

  # Rotasi milik sendiri (mahasiswa) atau yang saya bimbing (preseptor) yang
  # mulai/berakhir dalam 7 hari. Rotasi yang mulai hari ini cukup muncul
  # sekali sebagai "Akan Dimulai".
  def rotation_agenda(dates)
    scope = ClinicalRotation.where(user_id: current_user.id).or(ClinicalRotation.where(preceptor_id: current_user.id))
    starting = scope.where(start_date: dates).includes(:user).limit(AGENDA_LIMIT)
    ending = scope.where(end_date: dates).where(start_date: ...dates.begin).includes(:user).limit(AGENDA_LIMIT)

    starting.map { |r| rotation_agenda_item(r, r.start_date, "Akan Dimulai") } +
      ending.map { |r| rotation_agenda_item(r, r.end_date, "Akan Berakhir") }
  end

  def rotation_agenda_item(rotation, date, status_label)
    AgendaItem.new(kind: :rotasi, title: "Rotasi Klinik — #{rotation.station_name}",
                   person: other_person_name(rotation.user), location: rotation.institution_name.presence,
                   starts_at: date.in_time_zone, all_day: true,
                   status_label: status_label, status_tone: :emerald, path: clinical_rotations_path)
  end

  def tutorial_agenda(dates)
    scope = TutorialEnrollment.where(user_id: current_user.id).or(TutorialEnrollment.where(tutor_id: current_user.id)).active
    starting = scope.where(start_date: dates).includes(:user).limit(AGENDA_LIMIT)
    ending = scope.where(end_date: dates).where(start_date: ...dates.begin).includes(:user).limit(AGENDA_LIMIT)

    starting.map { |e| tutorial_agenda_item(e, e.start_date, "Blok Dimulai") } +
      ending.map { |e| tutorial_agenda_item(e, e.end_date, "Blok Berakhir") }
  end

  def tutorial_agenda_item(enrollment, date, status_label)
    AgendaItem.new(kind: :tutorial, title: "Tutorial — #{enrollment.block_name}",
                   person: other_person_name(enrollment.user), location: enrollment.group_name.presence,
                   starts_at: date.in_time_zone, all_day: true,
                   status_label: status_label, status_tone: :sky, path: tutorial_enrollments_path)
  end

  # Jadwal DOPS/Mini-CEX dari prodi — sebagai mahasiswa yang dinilai atau
  # sebagai penilai.
  def evaluation_schedule_agenda(window)
    EvaluationSchedule.for_user(current_user).where(status: "planned", scheduled_at: window)
                      .includes(:student, :evaluator, :clinical_rotation).order(:scheduled_at).limit(AGENDA_LIMIT).map do |s|
      as_student = s.student_id == current_user.id
      AgendaItem.new(kind: :penilaian, title: [ s.kind_label, s.topic.presence ].compact.join(" — "),
                     person: as_student ? s.evaluator&.full_name : s.student.full_name,
                     location: s.clinical_rotation&.institution_name.presence || s.clinical_rotation&.station_name,
                     starts_at: s.scheduled_at,
                     status_label: as_student ? "Akan Dinilai" : "Menilai", status_tone: :amber,
                     path: as_student ? assessments_path : dashboard_path(anchor: "jadwal-evaluasi"))
    end
  end

  # Ujian (jadwal percobaan atau tanggal event) & batas pengumpulan asesmen
  # rubrik milik mahasiswa, plus ujian yang saya uji sebagai penguji.
  def assessment_agenda(window, dates)
    on_date = "assessment_instances.scheduled_at BETWEEN :from AND :to OR " \
              "(assessment_instances.scheduled_at IS NULL AND assessment_events.exam_date BETWEEN :date_from AND :date_to)"
    date_params = { from: window.begin, to: window.end, date_from: dates.begin, date_to: dates.end }

    exams = current_user.assessment_instances.awaiting_score.joins(:assessment_event).where(on_date, date_params)
                        .includes(:assessment_event).limit(AGENDA_LIMIT).map do |i|
      assessment_agenda_item(i, title: i.assessment_event.name, status_label: i.assessment_event.type_label,
                                tone: :rose, path: student_assessment_path(i))
    end

    rubric_types = AssessmentEvent::TYPES.select { |_, (_, family)| family == :rubric }.keys
    deadlines = current_user.assessment_instances.where(status: "registered").joins(:assessment_event)
                            .where(assessment_events: { assessment_type: rubric_types, submission_close_at: window })
                            .includes(:assessment_event).limit(AGENDA_LIMIT).map do |i|
      AgendaItem.new(kind: :tenggat, title: "Kumpulkan: #{i.assessment_event.name}",
                     starts_at: i.assessment_event.submission_close_at, deadline: true,
                     status_label: "Batas Pengumpulan", status_tone: :amber, path: student_assessment_path(i))
    end

    examining = AssessmentInstance.for_examiner(current_user).awaiting_score.joins(:assessment_event).where(on_date, date_params)
                                  .includes(:assessment_event, :student).limit(AGENDA_LIMIT).map do |i|
      assessment_agenda_item(i, title: "Menguji — #{i.assessment_event.name}", person: i.student.full_name,
                                status_label: "Penguji", tone: :violet, path: examiner_evaluation_path(i))
    end

    exams + deadlines + examining
  end

  def assessment_agenda_item(instance, title:, status_label:, tone:, path:, person: nil)
    timed = instance.scheduled_at.present?
    AgendaItem.new(kind: :ujian, title: title, person: person,
                   starts_at: timed ? instance.scheduled_at : instance.assessment_event.exam_date.in_time_zone,
                   all_day: !timed, status_label: status_label, status_tone: tone, path: path)
  end

  # Tenggat milestone tugas akhir — sebagai mahasiswa atau pembimbing.
  def final_project_agenda(dates)
    FinalProjectMilestone.pending.joins(:final_project).where(target_date: dates)
                         .where("final_projects.student_id = :id OR final_projects.supervisor_id = :id", id: current_user.id)
                         .where.not(final_projects: { status: "completed" })
                         .includes(final_project: :student).order(:target_date).limit(AGENDA_LIMIT).map do |m|
      AgendaItem.new(kind: :tugas, title: m.title, person: other_person_name(m.final_project.student),
                     location: m.final_project.title, starts_at: m.target_date.in_time_zone, all_day: true, deadline: true,
                     status_label: "Tenggat Tugas Akhir", status_tone: :indigo, path: final_project_path(m.final_project))
    end
  end

  # Nama pihak lain hanya relevan bila BUKAN pengguna sendiri — di beranda
  # mahasiswa, "Rotasi · Siti" untuk rotasi Siti sendiri hanya bising.
  def other_person_name(person)
    return nil if person.nil? || person.id == current_user.id

    person.full_name
  end
end
