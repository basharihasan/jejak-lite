# frozen_string_literal: true

class ClinicalCasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_clinical_case, only: %i[show edit update destroy submit verify request_revision]

  def index
    @scope = params[:scope] == "to_verify" && current_user.can_verify_clinical_cases? ? "to_verify" : "mine"
    base_scope = @scope == "to_verify" ? ClinicalCase.awaiting_verification : current_user.clinical_cases
    @clinical_cases = base_scope.recent.page(params[:page])

    stats_scope = @scope == "to_verify" ? ClinicalCase.all : current_user.clinical_cases
    @stats = {
      total: stats_scope.count,
      by_status: stats_scope.group(:status).count,
      top_diagnoses: stats_scope.where.not(diagnosis: [ nil, "" ]).group(:diagnosis).count.sort_by { |_, c| -c }.first(5).to_h
    }
  end

  def show
    authorize @clinical_case
  end

  def new
    @clinical_case = current_user.clinical_cases.build(case_date: Date.current)
  end

  def create
    @clinical_case = current_user.clinical_cases.build(clinical_case_params)

    if @clinical_case.save
      redirect_to @clinical_case, notice: "Kasus klinis disimpan sebagai draf."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @clinical_case
  end

  def update
    authorize @clinical_case
    if @clinical_case.update(clinical_case_params)
      redirect_to @clinical_case, notice: "Kasus klinis diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @clinical_case
    @clinical_case.destroy
    redirect_to clinical_cases_path, notice: "Draf dihapus.", status: :see_other
  end

  def submit
    authorize @clinical_case
    @clinical_case.submit!
    redirect_to @clinical_case, notice: "Kasus klinis dikirim untuk verifikasi."
  end

  def verify
    authorize @clinical_case
    @clinical_case.verify!(
      by: current_user, entrustment_level: params[:entrustment_level],
      recommend_remediation: ActiveModel::Type::Boolean.new.cast(params[:recommend_remediation]) || false, comment: params[:comment]
    )
    redirect_to @clinical_case, notice: "Kasus klinis diverifikasi."
  end

  def request_revision
    authorize @clinical_case
    @clinical_case.request_revision!(by: current_user, comment: params[:comment])
    redirect_to @clinical_case, notice: "Permintaan revisi dikirim ke mahasiswa."
  end

  private

  def set_clinical_case
    @clinical_case = ClinicalCase.find(params[:id])
  end

  def clinical_case_params
    permitted = params.require(:clinical_case).permit(
      :case_date, :chief_complaint, :patient_age_group, :patient_gender,
      :clinical_setting, :case_complexity,
      :anamnesis, :general_condition, :physical_examination, :family_history,
      :diagnosis, :management, :learning_points, evidence_files: [],
      vital_signs: ClinicalCase::VITAL_SIGN_FIELDS.keys
    )
    permitted[:vital_signs] = permitted[:vital_signs].to_h.compact_blank if permitted[:vital_signs]
    permitted
  end
end
