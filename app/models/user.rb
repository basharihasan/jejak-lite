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
  has_many :supervised_clinical_cases, class_name: "ClinicalCase", foreign_key: :supervisor_id, inverse_of: :supervisor, dependent: :nullify
  has_many :clinical_rotations, dependent: :destroy # sebagai mahasiswa
  has_many :precepted_rotations, class_name: "ClinicalRotation", foreign_key: :preceptor_id, inverse_of: :preceptor, dependent: :nullify
  has_many :tutorial_enrollments, dependent: :destroy # sebagai mahasiswa (PSSK)
  has_many :tutored_enrollments, class_name: "TutorialEnrollment", foreign_key: :tutor_id, inverse_of: :tutor, dependent: :nullify
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
  has_many :assessment_instances, foreign_key: :student_id, inverse_of: :student, dependent: :destroy
  has_many :examined_assessment_instances, class_name: "AssessmentInstance", foreign_key: :examiner_id, inverse_of: :examiner, dependent: :nullify
  has_many :entrustment_decisions, foreign_key: :student_id, inverse_of: :student, dependent: :destroy

  # Peran yang boleh menilai/memverifikasi mahasiswa (DOPS, Mini-CEX, Kasus
  # Klinis) — dosen, preseptor (pembimbing klinis di wahana), dan admin.
  def instructor?
    has_role?("dosen") || has_role?("preseptor") || has_role?("admin")
  end
  alias can_verify_clinical_cases? instructor?

  # Calon pembimbing yang boleh ditandai mahasiswa pada kasus klinis.
  scope :case_supervisors, -> {
    where(id: UserRole.joins(:role).where(roles: { code: %w[dosen preseptor] }).select(:user_id)).order(:full_name)
  }

  # Boleh membuka halaman mahasiswa lain (Peta EPA dsb.) — pengajar, plus
  # kaprodi yang memantau tanpa menilai.
  def can_view_students?
    instructor? || has_role?("kaprodi")
  end

  # Assessment Form Builder (/assessment_form_templates) — membuat, menyunting,
  # mengisi, dan membaca jawaban formulir — hanya untuk kaprodi dan admin.
  def can_manage_assessment_forms?
    has_role?("admin") || has_role?("kaprodi")
  end

  # Kaprodi (bukan admin) terikat ke prodi akunnya: prodi itu membatasi apa
  # yang boleh ia lihat & ubah, jadi hanya admin yang boleh menggantinya.
  def study_program_bound?
    has_role?("kaprodi") && !has_role?("admin")
  end

  # Kata sandi bawaan akun hasil impor CSV / reset admin — publik & lemah,
  # jadi halaman Pengaturan Akun tetap satu-satunya tempat menggantinya.
  DEFAULT_PASSWORD = "password123"

  validates :full_name, presence: true

  GENDERS = { "Laki-laki" => "Laki-laki", "Perempuan" => "Perempuan" }.freeze
  PROFESSION_CATEGORIES = [
    "Dokter Umum", "Dokter Spesialis", "Dokter Gigi", "Dokter Gigi Spesialis",
    "Perawat", "Bidan", "Apoteker", "Tenaga Kesehatan Lain", "Non-Tenaga Kesehatan"
  ].freeze

  validates :gender, inclusion: { in: GENDERS.keys }, allow_blank: true
  validates :profession_category, inclusion: { in: PROFESSION_CATEGORIES }, allow_blank: true
  validates :cohort_year, numericality: { only_integer: true, greater_than: 1950, less_than_or_equal_to: ->(_u) { Date.current.year + 1 } }, allow_nil: true
  validates :phone, format: { with: /\A[0-9+().\- ]{6,25}\z/, message: "hanya boleh angka, spasi, dan tanda + ( ) - ." }, allow_blank: true
  validate :birth_date_not_in_future

  # Label nomor identitas mengikuti peran: mahasiswa memakai NPM/NIM,
  # selainnya NIP/NIDN — satu kolom, dua sebutan (seperti jejak.pro).
  def identifier_label
    has_role?("mahasiswa") ? "NPM / NIM" : "NIP / NIDN"
  end

  def age
    return nil if birth_date.blank?

    years = Date.current.year - birth_date.year
    years -= 1 if Date.current < birth_date + years.years
    years
  end

  def birth_place_and_date
    [ birth_place.presence, (birth_date ? I18n.l(birth_date, format: :long) : nil) ].compact.join(", ").presence
  end

  # Kelengkapan profil — dipakai kartu pengingat di halaman Profil. Isian yang
  # diminta berbeda per peran, jadi daftar ini dihitung, bukan tetap.
  def profile_required_fields
    common = { identifier_number: identifier_label, phone: "Nomor telepon", gender: "Jenis kelamin", birth_date: "Tanggal lahir" }
    if has_role?("mahasiswa")
      common.merge(study_program_id: "Program studi", cohort_year: "Angkatan")
    else
      common.merge(work_unit: "Unit kerja", position: "Jabatan")
    end
  end

  def missing_profile_fields
    profile_required_fields.reject { |attr, _| public_send(attr).present? }.values
  end

  def profile_completeness
    fields = profile_required_fields.keys
    filled = fields.count { |attr| public_send(attr).present? }
    ((filled / fields.size.to_f) * 100).round
  end

  # Instalasi tanpa server surat (production tanpa SMTP_ADDRESS) tidak bisa
  # mengirim email konfirmasi, jadi konfirmasi tidak diwajibkan di sana —
  # kalau tetap diwajibkan, akun hasil Daftar terkunci selamanya. Lingkungan
  # yang tidak menyetel flag ini (dev/test) dianggap bisa mengirim email.
  def self.email_delivery_enabled?
    Rails.configuration.x.email_delivery_enabled != false
  end

  def confirmation_required?
    super && self.class.email_delivery_enabled?
  end

  def postpone_email_change?
    super && self.class.email_delivery_enabled?
  end
  protected :confirmation_required?, :postpone_email_change?


  THEME_OPTIONS     = %w[light dark system].freeze
  FONT_SIZE_OPTIONS = %w[small normal large].freeze
  LOCALE_OPTIONS    = %w[id en].freeze
  validates :theme_preference, inclusion: { in: THEME_OPTIONS }
  validates :font_size_preference, inclusion: { in: FONT_SIZE_OPTIONS }
  validates :locale_preference, inclusion: { in: LOCALE_OPTIONS }

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

  # Relasi pembimbingan longgar: pernah menilai DOPS/Mini-CEX, membimbing
  # tugas akhir, atau memverifikasi kasus mahasiswa ini.
  def supervised_by?(instructor)
    dops_evaluations_as_student.exists?(evaluator: instructor) ||
      mini_cex_evaluations_as_student.exists?(evaluator: instructor) ||
      final_projects.exists?(supervisor: instructor) ||
      clinical_cases.exists?(verified_by: instructor)
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
  private

  def birth_date_not_in_future
    return if birth_date.blank?

    errors.add(:birth_date, "tidak boleh di masa depan") if birth_date > Date.current
  end
end
