# frozen_string_literal: true

class ClinicalCasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_clinical_case, only: %i[show edit update destroy submit verify request_revision break_glass issue_consent revoke_consent initiate_assessment]

  def index
    @scope = params[:scope] == "to_verify" && current_user.can_verify_clinical_cases? ? "to_verify" : "mine"
    base_scope = @scope == "to_verify" ? ClinicalCase.awaiting_verification : current_user.clinical_cases
    @clinical_cases = base_scope.recent.page(params[:page])
    @case_targets = @scope == "mine" ? case_target_progress : []

    stats_scope = @scope == "to_verify" ? ClinicalCase.all : current_user.clinical_cases
    @stats = {
      total: stats_scope.count,
      by_status: stats_scope.group(:status).count,
      top_diagnoses: stats_scope.where.not(diagnosis: [ nil, "" ]).group(:diagnosis).count.sort_by { |_, c| -c }.first(5).to_h
    }
  end

  def show
    authorize @clinical_case
    # Identitas pasien tersamar selama Privacy Mode menyala, kecuali pengguna
    # ini memegang Break Glass aktif untuk kasus ini.
    @privacy_mode = AppSetting.privacy_mode?
    @break_glass = BreakGlassAccess.active_for(current_user, @clinical_case) if @privacy_mode
    @identity_visible = !@privacy_mode || @break_glass.present?
    @patient_consent = @clinical_case.patient_consent
    # Tombol "Inisiasi CBD / Long Case": event berbasis kasus yang tampil bagi
    # pemilik kasus dan belum dipakai kasus ini.
    if policy(@clinical_case).initiate_assessment?
      used_event_ids = @clinical_case.assessment_instances.pluck(:assessment_event_id)
      @case_based_events = AssessmentEvent.published.where(assessment_type: %w[cbd long_case]).ordered
                                          .select { |e| e.visible_to?(@clinical_case.user) && e.submission_open? }
                                          .reject { |e| used_event_ids.include?(e.id) }
    end
    @case_assessments = @clinical_case.assessment_instances.includes(:assessment_event, :examiner)
  end

  # Inisiasi CBD / Long Case langsung dari kasus: kasus ini ditautkan ke
  # percobaan baru, penguji terisi dari verifier kasus atau preseptor rotasi
  # aktif, dan statusnya langsung "dikumpulkan" (kasusnya adalah dokumennya).
  def initiate_assessment
    authorize @clinical_case
    event = AssessmentEvent.published.where(assessment_type: %w[cbd long_case]).find(params[:assessment_event_id])
    unless event.visible_to?(current_user) && event.submission_open?
      redirect_to @clinical_case, alert: "Event ini tidak tersedia untuk Anda."
      return
    end
    if @clinical_case.assessment_instances.exists?(assessment_event: event)
      redirect_to @clinical_case, alert: "Kasus ini sudah diajukan ke #{event.name}."
      return
    end

    examiner = @clinical_case.verified_by || current_user.clinical_rotations.ongoing.first&.preceptor
    instance = current_user.assessment_instances.create!(
      assessment_event: event, attempt_number: AssessmentInstance.next_attempt_number(event, current_user),
      max_score: event.max_score, clinical_case: @clinical_case, examiner: examiner,
      status: "submitted", submitted_at: Time.current
    )
    if examiner
      Notification.notify!(recipient: examiner, sender: current_user, notifiable: instance,
                           title: "Permintaan #{event.type_label}", message: "#{current_user.full_name}: #{@clinical_case.chief_complaint}")
    end
    redirect_to student_assessment_path(instance), notice: "#{event.type_label} diinisiasi dari kasus ini."
  end

  # Break Glass: membuka identitas pasien untuk 30 menit dengan alasan tertulis;
  # setiap pembukaan tercatat permanen (BreakGlassAccess) dan terlihat admin di
  # Data Governance.
  def break_glass
    authorize @clinical_case
    access = BreakGlassAccess.new(user: current_user, clinical_case: @clinical_case,
                                  reason: params[:reason], expires_at: BreakGlassAccess::DURATION.from_now,
                                  ip_address: request.remote_ip)
    if access.save
      redirect_to @clinical_case, notice: "Identitas pasien dibuka sampai #{l(access.expires_at, format: :short)}. Akses ini tercatat."
    else
      redirect_to @clinical_case, alert: "Break Glass ditolak: #{access.errors.full_messages.to_sentence}"
    end
  end

  def issue_consent
    authorize @clinical_case
    @clinical_case.patient_consent&.destroy
    @clinical_case.create_patient_consent!
    redirect_to @clinical_case, notice: "QR persetujuan pasien diterbitkan. Minta pasien memindai atau membuka tautannya."
  end

  def revoke_consent
    authorize @clinical_case, :issue_consent?
    @clinical_case.patient_consent&.revoke!
    redirect_to @clinical_case, notice: "Persetujuan pasien dicabut.", status: :see_other
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
      recommend_remediation: ActiveModel::Type::Boolean.new.cast(params[:recommend_remediation]) || false, comment: params[:comment],
      epa_item_ids: Array(params[:epa_item_ids]).reject(&:blank?)
    )
    redirect_to @clinical_case, notice: "Kasus klinis diverifikasi."
  end

  def request_revision
    authorize @clinical_case
    @clinical_case.request_revision!(by: current_user, comment: params[:comment])
    redirect_to @clinical_case, notice: "Permintaan revisi dikirim ke mahasiswa."
  end

  private

  # Pemenuhan target kasus (FKTP/FKRTL) mahasiswa: kasus TERVERIFIKASI
  # dikelompokkan menurut ClinicalCase#facility_type.
  def case_target_progress
    targets = LogbookCaseTarget.applicable_for(current_user)
    return [] if targets.empty?

    verified = current_user.clinical_cases.where(status: "verified").group(:clinical_setting).count
    counts = Hash.new(0)
    verified.each { |setting, n| counts[setting == "pelayanan_primer" ? "fktp" : "fkrtl"] += n }
    targets.map { |t| { target: t, achieved: counts[t.facility_type] } }
  end

  def set_clinical_case
    @clinical_case = ClinicalCase.find(params[:id])
  end

  def clinical_case_params
    permitted = params.require(:clinical_case).permit(
      :case_date, :chief_complaint, :patient_age_group, :patient_gender,
      :patient_name, :patient_medical_record_number, :patient_birth_date, :patient_phone, :patient_address,
      :patient_age, :patient_occupation,
      :clinical_setting, :case_complexity,
      :anamnesis, :general_condition, :physical_examination, :family_history,
      :diagnosis, :management, :learning_points, evidence_files: [],
      prescription_items_attributes: %i[id medication_name strength dosage_form quantity signa route notes _destroy],
      vital_signs: ClinicalCase::VITAL_SIGN_FIELDS.keys
    )
    permitted[:vital_signs] = permitted[:vital_signs].to_h.compact_blank if permitted[:vital_signs]
    permitted
  end
end
