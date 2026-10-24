# frozen_string_literal: true

# Konfigurasi → Learning Unit: blok/modul dan Assessment Matrix-nya (event
# asesmen + bobot), serta rekap nilai unit per mahasiswa. Admin (semua prodi)
# dan kaprodi — kaprodi terikat ke prodi binaannya: hanya unit prodinya yang
# tampil, prodi unit dikunci ke prodinya, dan komponen matrix hanya dari event
# prodinya atau event lintas prodi.
class Admin::LearningUnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_unit, only: %i[show edit update destroy add_mapping remove_mapping]

  def index
    @units = unit_scope.includes(:study_program, :academic_period, :assessment_mappings).ordered
  end

  def show
    @mappings = @unit.assessment_mappings.includes(:assessment_event)
    @available_events = event_scope.ordered.where.not(id: @mappings.map(&:assessment_event_id))
    students = User.joins(:roles).where(roles: { code: "mahasiswa" }).where(study_program_id: @unit.study_program_id).distinct.order(:full_name)
    @recap = students.map { |s| { student: s, score: @unit.score_for(s), components: @unit.components_for(s) } }
  end

  def new
    @unit = LearningUnit.new(academic_period: AcademicPeriod.ordered.first)
    load_collections
  end

  def create
    @unit = LearningUnit.new(unit_params)
    if @unit.save
      redirect_to admin_learning_unit_path(@unit), notice: "Learning Unit dibuat. Tambahkan komponen Assessment Matrix-nya."
    else
      load_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_collections
  end

  def update
    if @unit.update(unit_params)
      redirect_to admin_learning_unit_path(@unit), notice: "Learning Unit diperbarui."
    else
      load_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy
    redirect_to admin_learning_units_path, notice: "Learning Unit dihapus.", status: :see_other
  end

  def add_mapping
    mapping = @unit.assessment_mappings.new(assessment_event: event_scope.find_by(id: params[:assessment_event_id]), weight: params[:weight])
    if mapping.save
      redirect_to admin_learning_unit_path(@unit), notice: "Komponen ditambahkan (#{mapping.weight}%). Total bobot sekarang #{@unit.reload.total_weight.round(1)}%."
    else
      redirect_to admin_learning_unit_path(@unit), alert: mapping.errors.full_messages.to_sentence
    end
  end

  def remove_mapping
    @unit.assessment_mappings.find(params[:mapping_id]).destroy
    redirect_to admin_learning_unit_path(@unit), notice: "Komponen dihapus.", status: :see_other
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

  def unit_scope
    current_user.study_program_bound? ? LearningUnit.where(study_program_id: current_user.study_program_id) : LearningUnit.all
  end

  def event_scope
    current_user.study_program_bound? ? AssessmentEvent.where(study_program_id: [ nil, current_user.study_program_id ]) : AssessmentEvent.all
  end

  def set_unit
    @unit = unit_scope.find(params[:id])
  end

  def load_collections
    @study_programs = current_user.study_program_bound? ? StudyProgram.where(id: current_user.study_program_id) : StudyProgram.ordered
    @academic_periods = AcademicPeriod.ordered
    @blueprints = AssessmentBlueprint.order(:name)
  end

  def unit_params
    permitted = params.require(:learning_unit).permit(:name, :code, :study_program_id, :academic_period_id, :credits, :description, :assessment_blueprint_id)
    permitted[:study_program_id] = current_user.study_program_id if current_user.study_program_bound?
    permitted
  end
end
