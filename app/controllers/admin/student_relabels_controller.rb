# frozen_string_literal: true

require "csv"

# Konfigurasi → Relabel Prodi Mahasiswa: pindahkan/labeli prodi mahasiswa
# secara massal dari CSV — pratinjau dulu, baru terapkan. Padanan
# /management/student_relabel jejak.pro; pencocokannya di
# StudentProgramRelabeler.
#
# Gerbang: admin (lintas prodi) atau kaprodi. Kaprodi terikat ke prodi
# akunnya sendiri (users.study_program_id): "pindah" hanya berlaku bagi
# mahasiswa prodinya, dan tujuan "klaim" dikunci server-side ke prodinya —
# target_study_program_id kiriman form diabaikan. Akun yang juga admin
# diperlakukan sebagai admin, sama seperti gerbang has_role? lainnya.
class Admin::StudentRelabelsController < ApplicationController
  MAX_FILE_SIZE = 2.megabytes

  before_action :authenticate_user!
  before_action :require_relabel_access!
  before_action :load_form_state

  helper_method :prodi_bound_viewer?, :own_study_program

  def new; end

  # GET /admin/student_relabel/template.csv
  def template
    csv = CSV.generate do |c|
      c << %w[email npm angkatan]
      c << [ "mahasiswa1@kampus.ac.id", nil, nil ]
      c << [ "2206000123", "1306230001", Date.current.year.to_s ]
    end
    send_data csv, filename: "template_relabel_prodi.csv", type: "text/csv"
  end

  # POST /admin/student_relabel — tanpa apply=1 hanya pratinjau.
  def create
    unless StudentProgramRelabeler::MODES.include?(@mode)
      return render_form_error("Pilih aksi yang valid.")
    end

    # Berkas hanya diunggah di tahap pratinjau; tahap terapkan mengirim ulang
    # isinya lewat hidden field csv_raw (input file tidak bisa di-resubmit).
    file = params[:csv_file]
    raw = file.respond_to?(:read) ? file.read : params[:csv_raw].to_s
    return render_form_error("Berkas terlalu besar — maksimal 2 MB.") if raw.bytesize > MAX_FILE_SIZE

    @csv_raw = StudentProgramRelabeler.normalize_csv(raw)
    @target_study_program_id = own_study_program.id if @mode == "klaim" && prodi_bound_viewer?
    target = StudyProgram.find_by(id: @target_study_program_id)

    relabeler = StudentProgramRelabeler.new(
      csv: @csv_raw, mode: @mode, target_study_program: target, actor: current_user,
      restrict_to_study_program_id: (own_study_program.id if @mode == "pindah" && prodi_bound_viewer?),
      default_cohort_year: @default_cohort_year
    )
    @matches = relabeler.matches
    if @matches.empty?
      return render_form_error("Unggah CSV berisi minimal satu baris data — unduh template dulu kalau belum punya.")
    end

    if params[:apply] == "1"
      result = relabeler.apply!
      redirect_to new_admin_student_relabel_path,
                  notice: "Relabel selesai — #{result.updated} akun kini berlabel #{target.name}, #{result.skipped} dilewati."
    else
      # Pratinjau: POST yang tidak redirect wajib non-2xx supaya Turbo mau
      # merender body-nya.
      @target_study_program = target
      render :new, status: :unprocessable_entity
    end
  rescue StudentProgramRelabeler::Error => e
    render_form_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_admin_student_relabel_path,
                alert: "Gagal menerapkan, tidak ada akun yang diubah: #{e.record.email} — #{e.record.errors.full_messages.to_sentence}"
  end

  private

  def require_relabel_access!
    unless current_user.has_role?("admin") || current_user.has_role?("kaprodi")
      return redirect_to dashboard_path, alert: "Halaman ini khusus admin/kaprodi."
    end
    return unless prodi_bound_viewer? && own_study_program.nil?

    redirect_to dashboard_path,
                alert: "Akun kaprodi Anda belum terhubung ke Program Studi — minta admin mengisinya di Konfigurasi → Pengguna."
  end

  def prodi_bound_viewer?
    return @prodi_bound_viewer if defined?(@prodi_bound_viewer)

    @prodi_bound_viewer = !current_user.has_role?("admin") && current_user.has_role?("kaprodi")
  end

  def own_study_program
    current_user.study_program
  end

  def load_form_state
    @study_programs = StudyProgram.ordered
    @mode = params[:mode].presence || "pindah"
    @target_study_program_id = params[:target_study_program_id].presence&.to_i
    @default_cohort_year = params[:default_cohort_year].to_s.strip.presence
  end

  def render_form_error(message)
    @matches = nil
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
