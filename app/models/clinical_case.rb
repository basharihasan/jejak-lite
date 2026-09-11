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

  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  has_many :case_verification_comments, -> { chronological }, dependent: :destroy

  has_many_attached :evidence_files

  validates :chief_complaint, :case_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :patient_age_group, inclusion: { in: AGE_GROUPS }, allow_blank: true
  validates :patient_gender, inclusion: { in: GENDERS }, allow_blank: true

  scope :recent, -> { order(case_date: :desc, created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }
  scope :awaiting_verification, -> { where(status: "submitted") }

  def status_label
    { "draft" => "Draf", "submitted" => "Menunggu Verifikasi", "verified" => "Terverifikasi", "needs_revision" => "Perlu Revisi" }.fetch(status, status)
  end

  def entrustment_level_label
    ENTRUSTMENT_LEVELS.fetch(entrustment_level, entrustment_level)
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
end
