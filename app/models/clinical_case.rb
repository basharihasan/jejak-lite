# frozen_string_literal: true

class ClinicalCase < ApplicationRecord
  include ClinicalContextOptions

  STATUSES = %w[draft submitted verified needs_revision].freeze
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

  before_save :sync_diagnosis_definition

  has_many :case_verification_comments, -> { chronological }, dependent: :destroy

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
    { "draft" => "Draf", "submitted" => "Menunggu Verifikasi", "verified" => "Terverifikasi", "needs_revision" => "Perlu Revisi" }.fetch(status, status)
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

  def verify!(by:, entrustment_level: nil, recommend_remediation: false, comment: nil)
    update!(
      status: "verified", verified_by: by, verified_at: Time.current,
      entrustment_level: entrustment_level, recommend_remediation: recommend_remediation
    )
    case_verification_comments.create!(user: by, action: "verified", body: comment)
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
