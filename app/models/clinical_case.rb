# frozen_string_literal: true

class ClinicalCase < ApplicationRecord
  include ClinicalContextOptions

  # rejected = final: kasus tidak layak dijadikan bukti (mis. bukan kasus
  # sungguhan/duplikat) — beda dari needs_revision yang masih bisa diperbaiki.
  STATUSES = %w[draft submitted verified needs_revision rejected].freeze
  AGE_GROUPS = %w[Anak Dewasa Lansia].freeze
  GENDERS = %w[Laki-laki Perempuan].freeze

  # Skala entrustment 6 level meniru JEJAK asli — diisi verifier saat
  # menyetujui kasus, bukan mahasiswa. Bukan cuma "terverifikasi/tidak" —
  # menandai seberapa mandiri mahasiswa melakukannya.
  ENTRUSTMENT_LEVELS = {
    "diobservasi" => "Diobservasi",
    "dibantu" => "Dibantu",
    "supervisi_langsung" => "Dilakukan dengan Supervisi Langsung",
    "supervisi_tidak_langsung" => "Dilakukan dengan Supervisi Tidak Langsung",
    "mandiri" => "Dilakukan Mandiri",
    "mengajari_junior" => "Mengajari Junior"
  }.freeze

  # Tanda vital sengaja JSONB longgar (bukan kolom per-tanda) — meniru
  # struktur data JEJAK asli tanpa membangun modul antropometri penuh
  # (lingkar kepala/LiLA dsb yang JEJAK punya sebagai "tambahan" opsional).
  VITAL_SIGN_FIELDS = {
    "temperature" => "Suhu (°C)",
    "bp_systolic" => "TD Sistol",
    "bp_diastolic" => "TD Diastol",
    "pulse" => "Nadi (bpm)",
    "respiratory_rate" => "Respirasi (x/mnt)",
    "weight_kg" => "BB (kg)",
    "height_cm" => "TB (cm)"
  }.freeze

  # Judul langkah wizard & pemetaan atribut -> langkah untuk menunjuk galat.
  WIZARD_STEPS = [
    "Identitas & Demografi", "Anamnesis, Pemeriksaan Fisik & Tanda Vital", "Pemeriksaan Penunjang",
    "Diagnosis & Tatalaksana", "Terapi & Resep", "Pembelajaran & Bukti"
  ].freeze
  WIZARD_STEP_ATTRIBUTES = {
    1 => %w[anamnesis general_condition physical_examination family_history vital_signs],
    2 => %w[laboratory_results radiology_results other_investigations],
    3 => %w[diagnosis icd10_code skdi_level management],
    4 => %w[prescription_items],
    5 => %w[learning_points evidence_files]
  }.freeze

  def self.wizard_step_for(attribute)
    name = attribute.to_s.split(".").first
    WIZARD_STEP_ATTRIBUTES.find { |_step, attrs| attrs.include?(name) }&.first || 0
  end

  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  # Identitas pasien — terenkripsi di basis data (Active Record Encryption)
  # dan DISAMARKAN di tampilan selama Privacy Mode menyala; dibuka hanya lewat
  # Break Glass beralasan (lihat BreakGlassAccess). Usia persis, jenis kelamin,
  # dan pekerjaan sengaja tidak termasuk (bukan data sensitif).
  encrypts :patient_name, :patient_medical_record_number, :patient_birth_date, :patient_phone, :patient_address
  SENSITIVE_PATIENT_FIELDS = %i[patient_name patient_medical_record_number patient_birth_date patient_phone patient_address].freeze

  has_many :break_glass_accesses, dependent: :destroy
  has_one :patient_consent, dependent: :destroy
  has_many :assessment_instances, dependent: :nullify # CBD / Long Case yang berangkat dari kasus ini
  has_many :dops_evaluations, dependent: :nullify      # DOPS / Mini-CEX yang diinisiasi dari kasus ini
  has_many :mini_cex_evaluations, dependent: :nullify

  before_save :sync_diagnosis_definition

  has_many :case_verification_comments, -> { chronological }, dependent: :destroy
  # Latihan menulis resep: baris resep terstruktur milik kasus ini.
  has_many :prescription_items, -> { ordered }, dependent: :destroy, inverse_of: :clinical_case
  accepts_nested_attributes_for :prescription_items, allow_destroy: true

  has_many_attached :evidence_files

  validates :chief_complaint, :case_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :patient_age_group, inclusion: { in: AGE_GROUPS }, allow_blank: true
  validates :patient_gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :patient_age, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 150 }, allow_nil: true
  validate :patient_birth_date_is_a_date

  scope :recent, -> { order(case_date: :desc, created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }
  scope :awaiting_verification, -> { where(status: "submitted") }

  def status_label
    { "draft" => "Draf", "submitted" => "Menunggu Verifikasi", "verified" => "Terverifikasi", "needs_revision" => "Perlu Revisi", "rejected" => "Ditolak" }.fetch(status, status)
  end

  def entrustment_level_label
    ENTRUSTMENT_LEVELS.fetch(entrustment_level, entrustment_level)
  end

  def vital_sign(key)
    vital_signs&.dig(key.to_s)
  end

  def bmi
    weight = vital_sign("weight_kg").to_f
    height_m = vital_sign("height_cm").to_f / 100.0
    return nil if weight.zero? || height_m.zero?

    (weight / (height_m**2)).round(1)
  end

  def editable_by_owner?
    %w[draft needs_revision].include?(status)
  end

  def submit!
    update!(status: "submitted")
    case_verification_comments.create!(user: user, action: "submitted")
  end

  def verify!(by:, entrustment_level: nil, recommend_remediation: false, comment: nil, epa_item_ids: [])
    update!(
      status: "verified", verified_by: by, verified_at: Time.current,
      entrustment_level: entrustment_level, recommend_remediation: recommend_remediation
    )
    case_verification_comments.create!(user: by, action: "verified", body: comment)
    record_entrustment_decisions!(by: by, epa_item_ids: epa_item_ids)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kasus klinis terverifikasi", message: chief_complaint
    )
  end

  def request_revision!(by:, comment:)
    update!(status: "needs_revision", verified_by: by, verified_at: Time.current)
    case_verification_comments.create!(user: by, action: "revision_requested", body: comment)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kasus klinis perlu direvisi", message: comment
    )
  end
  def reject!(by:, comment:)
    update!(status: "rejected", verified_by: by, verified_at: Time.current)
    case_verification_comments.create!(user: by, action: "rejected", body: comment)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kasus klinis ditolak", message: comment
    )
  end

  # Membatalkan verifikasi: kasus kembali ke antrean "Menunggu Verifikasi" dan
  # level entrustment EPA yang ditulis verifikasi ini dicabut (keputusan
  # sebelumnya dipulihkan) — Peta EPA tidak boleh memuat level dari
  # verifikasi yang sudah dibatalkan.
  def cancel_verification!(by:, reason:)
    transaction do
      update!(status: "submitted", verified_by: nil, verified_at: nil,
              entrustment_level: nil, recommend_remediation: false)
      EntrustmentDecision.revoke_for_case!(self)
      case_verification_comments.create!(user: by, action: "verification_cancelled", body: reason)
    end
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Verifikasi kasus klinis dibatalkan", message: reason
    )
  end

  # Komentar verifikasi tanpa mengubah status — diskusi pemilik ↔ verifier.
  def add_verification_comment!(by:, body:)
    comment = case_verification_comments.create!(user: by, action: "commented", body: body)
    recipient = by.id == user_id ? verified_by : user
    if recipient && recipient.id != by.id
      Notification.notify!(recipient: recipient, sender: by, notifiable: self,
                           title: "Komentar baru pada kasus klinis", message: body)
    end
    comment
  end

  # Baris resep yang BENAR-BENAR kosong dibuang diam-diam (mahasiswa menambah
  # baris lalu tidak jadi memakainya); baris yang sudah terisi sebagian tetapi
  # tanpa nama obat DITAHAN dan dilaporkan — isian yang sudah diketik tidak
  # boleh hilang tanpa jejak.
  def prescription_items_attributes=(attributes)
    cleaned = attributes.to_h.reject do |_index, row|
      next false if row["id"].present? || row[:id].present?

      %w[medication_name strength dosage_form quantity signa route notes].all? { |key| row[key].blank? && row[key.to_sym].blank? }
    end
    super(cleaned)
  end

  def prescription?
    prescription_items.any?
  end

  def patient_identity_present?
    SENSITIVE_PATIENT_FIELDS.any? { |f| public_send(f).present? }
  end

  def patient_birth_date_as_date
    return nil if patient_birth_date.blank?

    Date.iso8601(patient_birth_date)
  rescue Date::Error
    nil
  end

  # Usia yang ditampilkan: kolom patient_age bila diisi, kalau tidak dihitung
  # dari tanggal lahir terhadap tanggal kasus.
  def display_age
    return patient_age if patient_age.present?

    dob = patient_birth_date_as_date
    return nil unless dob && case_date

    age = case_date.year - dob.year
    age -= 1 if case_date < dob + age.years
    age
  end

  # Samaran identitas ala JEJAK: inisial nama + "***", No. RM disembunyikan
  # kecuali dua digit terakhir.
  def masked_patient_name
    return nil if patient_name.blank?

    initials = patient_name.split.map { |w| w[0] }.join.upcase
    "#{initials[0, 3]}***"
  end

  def masked_medical_record_number
    return nil if patient_medical_record_number.blank?

    "RM-****#{patient_medical_record_number.to_s.last(2)}"
  end

  # FKTP = pelayanan primer; selainnya (RS: rawat jalan/inap, IGD, ICU, OK) = FKRTL.
  def facility_type
    clinical_setting == "pelayanan_primer" ? "fktp" : "fkrtl"
  end

  # Verifikasi menulis level entrustment EPA untuk ranah yang dipilih verifier
  # (peta 6 level kasus → skala 1–5, lihat EntrustmentDecision::CASE_LEVEL_MAP).
  # Tanpa ranah terpilih tidak ada yang ditulis — tidak menebak.
  def record_entrustment_decisions!(by:, epa_item_ids:)
    level = EntrustmentDecision::CASE_LEVEL_MAP[entrustment_level]
    return if level.nil? || epa_item_ids.blank?

    CompetencyItem.where(id: epa_item_ids, parent_id: nil).find_each do |item|
      EntrustmentDecision.decide!(
        student: user, competency_item: item, level: level, decided_by: by, clinical_case: self,
        justification: "Verifikasi kasus \"#{chief_complaint}\" (#{I18n.l(case_date, format: :long)}): #{entrustment_level_label}."
      )
    end
  end

  private

  def patient_birth_date_is_a_date
    return if patient_birth_date.blank?

    errors.add(:patient_birth_date, "bukan tanggal yang valid") if patient_birth_date_as_date.nil?
  end

  # Cocokkan teks diagnosis dengan master DiagnosisDefinition supaya kode
  # ICD-10 & level SKDI terisi tanpa mahasiswa mengetik kode.
  def sync_diagnosis_definition
    return unless will_save_change_to_diagnosis?

    definition = DiagnosisDefinition.match(diagnosis)
    self.icd10_code = definition&.icd10_code
    self.skdi_level = definition&.skdi_level
  end
end
