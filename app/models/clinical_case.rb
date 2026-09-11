# frozen_string_literal: true

class ClinicalCase < ApplicationRecord
  STATUSES = %w[draft submitted verified needs_revision].freeze
  AGE_GROUPS = %w[Anak Dewasa Lansia].freeze
  GENDERS = %w[Laki-laki Perempuan].freeze

  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

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

  def editable_by_owner?
    %w[draft needs_revision].include?(status)
  end

  def submit!
    update!(status: "submitted")
  end

  def verify!(by:)
    update!(status: "verified", verified_by: by, verified_at: Time.current, verification_comment: nil)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kasus klinis terverifikasi", message: chief_complaint
    )
  end

  def request_revision!(by:, comment:)
    update!(status: "needs_revision", verified_by: by, verified_at: Time.current, verification_comment: comment)
    Notification.notify!(
      recipient: user, sender: by, notifiable: self,
      title: "Kasus klinis perlu direvisi", message: comment
    )
  end
end
