# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  belongs_to :active_role, class_name: "Role", optional: true

  has_one_attached :avatar

  has_many :notifications, foreign_key: :recipient_id, inverse_of: :recipient, dependent: :destroy
  has_many :device_push_tokens, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :clinical_cases, dependent: :destroy
  has_many :verified_clinical_cases, class_name: "ClinicalCase", foreign_key: :verified_by_id, inverse_of: :verified_by, dependent: :nullify
  has_many :clinical_rotations, dependent: :destroy # sebagai mahasiswa
  has_many :precepted_rotations, class_name: "ClinicalRotation", foreign_key: :preceptor_id, inverse_of: :preceptor, dependent: :nullify
  belongs_to :study_program, optional: true
  has_many :reflection_entries, dependent: :destroy
  has_many :dops_evaluations_as_student, class_name: "DopsEvaluation", foreign_key: :student_id, inverse_of: :student, dependent: :destroy
  has_many :dops_evaluations_as_evaluator, class_name: "DopsEvaluation", foreign_key: :evaluator_id, inverse_of: :evaluator, dependent: :destroy
  has_many :mini_cex_evaluations_as_student, class_name: "MiniCexEvaluation", foreign_key: :student_id, inverse_of: :student, dependent: :destroy
  has_many :mini_cex_evaluations_as_evaluator, class_name: "MiniCexEvaluation", foreign_key: :evaluator_id, inverse_of: :evaluator, dependent: :destroy
  has_many :assessment_form_submissions, foreign_key: :respondent_id, inverse_of: :respondent, dependent: :destroy
  has_many :final_projects, foreign_key: :student_id, inverse_of: :student, dependent: :destroy
  has_many :supervised_final_projects, class_name: "FinalProject", foreign_key: :supervisor_id, inverse_of: :supervisor, dependent: :nullify
  has_many :examiner_scores_given, class_name: "ExaminerScore", foreign_key: :examiner_id, inverse_of: :examiner, dependent: :destroy

  # Peran yang boleh menilai/memverifikasi mahasiswa (DOPS, Mini-CEX, Kasus
  # Klinis). Belum ada peran `preseptor` (menyusul Fase Dashboard Analitik)
  # — untuk sekarang dosen dan admin yang berwenang.
  def instructor?
    has_role?("dosen") || has_role?("admin")
  end
  alias can_verify_clinical_cases? instructor?

  validates :full_name, presence: true

  # Akun yang masuk lewat Google tidak pernah mengisi form registrasi biasa,
  # jadi password acak + confirmed_at langsung diisi di sini (bukan lewat
  # alur konfirmasi email Devise) — konsisten dengan pola Google-login yang
  # "sudah terverifikasi oleh Google".
  def self.from_google_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email ||= auth.info.email
    user.full_name = auth.info.name if user.full_name.blank?

    if user.new_record?
      user.password = Devise.friendly_token[0, 20]
      user.confirmed_at = Time.current
    end

    user.save
    user
  end

  def has_role?(code)
    roles.exists?(code: code.to_s)
  end

  # Menukar peran aktif — dipakai fitur "Ganti Peran". Menolak pindah ke
  # peran yang tidak dimiliki, supaya Dashboard tidak pernah bercabang ke
  # peran yang sebenarnya tidak disandang user ini.
  def switch_active_role!(role_code)
    role = roles.find_by(code: role_code.to_s)
    return false unless role

    update(active_role: role)
  end

  # Token acak untuk URL feed iCal pribadi (/activity_logs/feed/:token.ics).
  # Dibuat lazy saat pertama diminta, bukan saat akun dibuat, supaya akun
  # yang tak pernah membuka fitur kalender tak menyimpan token yang tak
  # terpakai.
  def calendar_feed_token!
    return calendar_feed_token if calendar_feed_token.present?

    update!(calendar_feed_token: SecureRandom.urlsafe_base64(24))
    calendar_feed_token
  end
end
