# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  CATEGORIES = { "klinis" => "Klinis", "non_klinis" => "Non-Klinis" }.freeze
  DELIVERY_MODES = { "luring" => "Luring", "daring" => "Daring" }.freeze

  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  # Taksonomi jejak.pro: Domain → Subdomain (kategori) → Bentuk Kegiatan.
  # Kegiatan lama (sebelum 17 Sep 2026) hanya punya `category` + teks bebas
  # `activity_type`; keduanya tetap dibaca lewat *_label di bawah.
  belongs_to :academic_activity_domain, optional: true
  belongs_to :academic_activity_subdomain, optional: true
  belongs_to :academic_activity_template, optional: true
  belongs_to :academic_period, optional: true
  belongs_to :clinical_rotation, optional: true

  has_many :activity_log_competency_tags, dependent: :destroy
  has_many :competency_items, through: :activity_log_competency_tags

  has_many_attached :evidence_files

  # Dinyalakan ActivityLogsController: isian yang wajib di form (domain,
  # waktu mulai, metode) tidak dipaksakan pada jalur lain — fixture, demo,
  # dan kegiatan lama yang belum pernah disunting.
  attribute :require_form_fields, :boolean, default: false

  before_validation :complete_taxonomy
  before_validation :derive_from_taxonomy_and_time

  validates :title, :activity_date, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :delivery_mode, inclusion: { in: DELIVERY_MODES.keys }, allow_blank: true
  validates :evidence_url, :document_url,
            format: { with: %r{\Ahttps?://\S+\z}i, message: "harus diawali http:// atau https://" },
            length: { maximum: 2000 }, allow_blank: true

  with_options if: :require_form_fields do
    validates :academic_activity_domain, presence: { message: "wajib dipilih" }
    validates :started_at, presence: { message: "wajib diisi" }
    validates :delivery_mode, presence: { message: "wajib dipilih (Daring atau Luring)" }
    validate :new_taxonomy_choice_is_active
  end

  validate :taxonomy_is_consistent
  validate :ended_after_started
  validate :rotation_belongs_to_owner

  scope :recent, -> { order(activity_date: :desc, started_at: :desc, created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }
  scope :awaiting_verification, -> { where(verified_at: nil) }
  scope :verified, -> { where.not(verified_at: nil) }
  scope :klinis, -> { where(category: "klinis") }
  scope :non_klinis, -> { where(category: "non_klinis") }
  scope :in_domain, ->(domain_id) { where(academic_activity_domain_id: domain_id) }
  scope :in_month, ->(date) { where(activity_date: date.beginning_of_month..date.end_of_month) }
  scope :tagged_with, ->(competency_item_id) { joins(:activity_log_competency_tags).where(activity_log_competency_tags: { competency_item_id: competency_item_id }) }
  scope :with_taxonomy, -> { includes(:academic_activity_domain, :academic_activity_subdomain, :academic_activity_template) }

  def delivery_mode_label
    DELIVERY_MODES.fetch(delivery_mode, delivery_mode)
  end

  def category_label
    CATEGORIES.fetch(category, category)
  end

  def clinical?
    category == "klinis"
  end

  # Label tingkat atas: nama domain, atau Klinis/Non-Klinis untuk kegiatan lama.
  def domain_label
    academic_activity_domain&.name || category_label
  end

  def domain_color
    academic_activity_domain&.color || (clinical? ? "#0284c7" : "#059669")
  end

  # Label rinci: Bentuk Kegiatan, lalu Subdomain, lalu teks bebas lama.
  def kind_label
    academic_activity_template&.name || academic_activity_subdomain&.name || activity_type.presence
  end

  # "Subdomain · Bentuk Kegiatan" — untuk ringkasan satu baris.
  def taxonomy_detail
    [ academic_activity_subdomain&.name, academic_activity_template&.name ].compact.join(" · ").presence || activity_type.presence
  end

  def verified?
    verified_at.present?
  end

  def verify!(by:)
    update!(verified_at: Time.current, verified_by: by)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kegiatan terverifikasi", message: title
    )
  end

  # Kode acak non-identifikasi (bukan nama/RM pasien) — cuma penanda supaya
  # mahasiswa bisa menautkan beberapa entri logbook ke "pasien yang sama"
  # tanpa menyimpan data pribadi apa pun. Dibuat sekali, dipakai ulang.
  def ensure_patient_code!
    return patient_code if patient_code.present?

    update!(patient_code: "P-#{SecureRandom.alphanumeric(8).upcase}")
    patient_code
  end

  private

  # Isian tingkat bawah cukup untuk menurunkan tingkat di atasnya.
  def complete_taxonomy
    if academic_activity_template && academic_activity_subdomain_id.blank?
      self.academic_activity_subdomain = academic_activity_template.academic_activity_subdomain
    end
    if academic_activity_subdomain && academic_activity_domain_id.blank?
      self.academic_activity_domain = academic_activity_subdomain.academic_activity_domain
    end
  end

  # `category` & `activity_date` tetap disimpan karena dibaca Portfolio,
  # kalender, feed iCal, dan paket migrasi — nilainya kini turunan.
  def derive_from_taxonomy_and_time
    self.category = academic_activity_domain.is_clinical? ? "klinis" : "non_klinis" if academic_activity_domain
    self.activity_date = started_at.in_time_zone.to_date if started_at
    self.academic_period ||= single_period_covering(activity_date) if activity_date
  end

  # Semester hanya diisi otomatis bila tepat satu periode mencakup tanggalnya —
  # periode yang tumpang-tindih dibiarkan kosong daripada ditebak.
  def single_period_covering(date)
    periods = AcademicPeriod.where("start_date <= :date AND end_date >= :date", date: date).limit(2).to_a
    periods.first if periods.one?
  end

  def taxonomy_is_consistent
    if academic_activity_subdomain && academic_activity_subdomain.academic_activity_domain_id != academic_activity_domain_id
      errors.add(:academic_activity_subdomain, "tidak termasuk domain yang dipilih")
    end
    if academic_activity_template && academic_activity_template.academic_activity_subdomain_id != academic_activity_subdomain_id
      errors.add(:academic_activity_template, "tidak termasuk subdomain yang dipilih")
    end
  end

  # Pilihan yang sudah dinonaktifkan admin tetap sah bila memang sudah
  # tersimpan (kegiatan lama), tapi tidak boleh dipilih baru.
  def new_taxonomy_choice_is_active
    %i[academic_activity_domain academic_activity_subdomain academic_activity_template].each do |name|
      record = public_send(name)
      next if record.nil? || record.is_active? || !will_save_change_to_attribute?("#{name}_id")

      errors.add(name, "sudah dinonaktifkan admin")
    end
  end

  def ended_after_started
    return if started_at.blank? || ended_at.blank?

    errors.add(:ended_at, "harus setelah waktu mulai") if ended_at < started_at
  end

  def rotation_belongs_to_owner
    return if clinical_rotation.nil? || clinical_rotation.user_id == user_id

    errors.add(:clinical_rotation, "bukan rotasi milik pemilik kegiatan ini")
  end
end
