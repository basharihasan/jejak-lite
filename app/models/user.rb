# frozen_string_literal: true

class User < ApplicationRecord
  include AttachmentValidation
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :lockable, :timeoutable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  belongs_to :active_role, class_name: "Role", optional: true

  has_one_attached :avatar
  validates_attachments :avatar, content_types: WEB_IMAGE_TYPES, max_size: 5.megabytes

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
  has_many :data_export_logs, dependent: :destroy
  has_many :srq_screenings, dependent: :destroy
  has_many :followed_up_srq_screenings, class_name: "SrqScreening", foreign_key: :followed_up_by_id,
                                        inverse_of: :followed_up_by, dependent: :nullify

  # Peran yang boleh menilai/memverifikasi mahasiswa (DOPS, Mini-CEX, Kasus
  # Klinis) — dosen, preseptor (pembimbing klinis di wahana), dan admin.
  def instructor?
    has_role?("dosen") || has_role?("preseptor") || has_role?("admin")
  end
  alias can_verify_clinical_cases? instructor?

  # Akun nonaktif tidak bisa masuk dan tidak ikut daftar pilihan atau hitungan
  # prodi, tetapi rekam jejak pendidikannya tetap ada.
  scope :active_accounts, -> { where(deactivated_at: nil) }

  # Calon pembimbing yang boleh ditandai mahasiswa pada kasus klinis.
  scope :case_supervisors, -> {
    active_accounts.where(id: UserRole.joins(:role).where(roles: { code: %w[dosen preseptor] }).select(:user_id)).order(:full_name)
  }

  # Boleh membuka halaman mahasiswa lain (Peta EPA dsb.) — pengajar, plus
  # kaprodi yang memantau tanpa menilai.
  def can_view_students?
    instructor? || has_role?("kaprodi")
  end

  # Monitoring SRQ: data kesehatan mental, jadi hanya kaprodi yang terhubung ke
  # prodi. Admin tidak otomatis ikut, berbeda dari fitur lain.
  # Kaprodi tanpa peran admin terikat prodi, jadi prodinya wajib ada. Dipakai
  # impor CSV dan Sunting Pengguna supaya akun seperti itu tidak terbentuk.
  def self.program_required_for_roles?(codes)
    codes.include?("kaprodi") && codes.exclude?("admin")
  end

  # SRQ-20 tampil bagi mahasiswa setelah kaprodi mengaktifkannya untuk prodinya.
  def can_fill_srq?
    has_role?("mahasiswa") && study_program&.srq_enabled? == true
  end

  # Hasil yang sudah ada tetap bisa dibuka pemiliknya walau SRQ dimatikan lagi.
  def srq_accessible?
    can_fill_srq? || (has_role?("mahasiswa") && srq_screenings.exists?)
  end

  def can_monitor_srq?
    has_role?("kaprodi") && study_program_id.present?
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

  # Boleh membuka data satu mahasiswa tertentu (Dasbor Mahasiswa dan halaman
  # asesmen ber-?student_id=). Targetnya harus mahasiswa — bukan akun dosen/
  # admin — dan kaprodi non-admin hanya untuk mahasiswa prodi binaannya.
  def can_view_student?(student)
    return false unless student && can_view_students? && student.has_role?("mahasiswa")
    return study_program_id.present? && student.study_program_id == study_program_id if study_program_bound?

    true
  end

  # Kata sandi bawaan lama untuk akun hasil impor CSV / reset admin — tercantum
  # publik di repositori. Akun baru tidak lagi memakainya (lihat
  # assign_temporary_password), tetapi akun lama yang masih memakainya
  # ditandai wajib ganti saat masuk (valid_password?).
  LEGACY_DEFAULT_PASSWORD = "password123"

  # Akun contoh `bin/rails demo:seed` sengaja berkata sandi publik dan dipakai
  # bergantian banyak orang — tidak dipaksa ganti kata sandi, kalau tidak
  # pengunjung pertama mengunci semua pengunjung berikutnya.
  DEMO_EMAIL_DOMAIN = "jejakessential.test"

  # Huruf/angka yang tak mudah tertukar saat didikte atau disalin dari kertas
  # (tanpa 0/O, 1/l/I).
  TEMPORARY_PASSWORD_ALPHABET = (("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a - %w[l I O]).freeze

  validates :full_name, presence: true
  validate :password_not_legacy_default

  before_save :clear_must_change_password, if: :will_save_change_to_encrypted_password?

  def self.generate_temporary_password
    Array.new(3) { Array.new(4) { TEMPORARY_PASSWORD_ALPHABET.sample(random: SecureRandom) }.join }.join("-")
  end

  # Kata sandi sementara acak untuk akun hasil impor CSV atau reset admin —
  # ditampilkan sekali ke admin, lalu pengguna wajib menggantinya saat masuk.
  # Mengembalikan kata sandinya (belum disimpan; panggil save sesudahnya).
  def assign_temporary_password
    temporary = self.class.generate_temporary_password
    self.password = self.password_confirmation = temporary
    self.must_change_password = true
    @temporary_password_assigned = true
    temporary
  end

  def deactivated? = deactivated_at.present?

  def active_for_authentication? = super && !deactivated?

  def inactive_message = deactivated? ? :deactivated : super

  # Rujukan yang ikut hilang bersama akun tanpa menghapus rekam jejak apa pun.
  DISPOSABLE_REFERENCES = [ %w[user_roles user_id], %w[notifications recipient_id], %w[device_push_tokens user_id] ].freeze

  # Hapus permanen hanya untuk akun tanpa rekam jejak, mis. akun salah daftar.
  # dependent: :destroy di atas akan ikut menghapus logbook dan nilai, jadi
  # akun yang sudah punya riwayat dinonaktifkan, bukan dihapus. Diperiksa lewat
  # foreign key supaya tabel baru otomatis ikut dihitung.
  def deletable?
    connection = self.class.connection
    connection.tables.none? do |table|
      connection.foreign_keys(table).any? do |key|
        next false unless key.to_table == "users"
        next false if DISPOSABLE_REFERENCES.include?([ table, key.column ])

        rows = Arel::Table.new(table)
        connection.select_value(rows.project(Arel.sql("1")).where(rows[key.column].eq(id)).take(1)).present?
      end
    end
  end

  def demo_account?
    email.to_s.end_with?("@#{DEMO_EMAIL_DOMAIN}")
  end

  # Tandai wajib ganti bila seseorang berhasil masuk memakai kata sandi
  # bawaan lama yang publik. Dicek di sini karena hanya saat login kata sandi
  # aslinya tersedia — tanpa bcrypt tambahan.
  def valid_password?(password)
    super.tap do |valid|
      if valid && password == LEGACY_DEFAULT_PASSWORD && !demo_account? && !must_change_password?
        update_column(:must_change_password, true)
      end
    end
  end

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
  # selainnya NIP/NIDN — satu kolom, dua sebutan.
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
    # Pendaftaran mandiri ditutup: hanya akun Google yang sudah ada boleh masuk.
    return nil if user.new_record? && !AppSetting.registration_open?

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

  # Memuat peran sekali per objek lalu memeriksa di memori — dulu satu query
  # per panggilan (sampai 36 kali per request lewat sidebar & policy).
  # `roles <<` dan `role_ids=` ikut memperbarui koleksi yang sudah dimuat,
  # jadi hasilnya tidak basi setelah peran diubah lewat asosiasi ini.
  def has_role?(code)
    roles.any? { |role| role.code == code.to_s }
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

  # Kata sandi apa pun yang disimpan selain kata sandi sementara (ganti
  # sendiri di Pengaturan Akun, reset lewat email) melepas kewajiban ganti.
  def clear_must_change_password
    if @temporary_password_assigned
      @temporary_password_assigned = false
    else
      self.must_change_password = false
    end
  end

  # Kata sandi bawaan lama tercantum publik di repositori — tidak boleh dipilih
  # lagi, kecuali untuk akun demo yang memang berkata sandi publik.
  def password_not_legacy_default
    return unless password == LEGACY_DEFAULT_PASSWORD && !demo_account?

    errors.add(:password, "terlalu mudah ditebak — kata sandi ini tercantum publik, pilih yang lain")
  end

  def birth_date_not_in_future
    return if birth_date.blank?

    errors.add(:birth_date, "tidak boleh di masa depan") if birth_date > Date.current
  end
end
