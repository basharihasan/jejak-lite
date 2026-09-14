# frozen_string_literal: true

# Enrolment Tutorial — padanan PSSK dari ClinicalRotation (PSPD): mahasiswa
# terdaftar pada satu blok/sistem dengan satu dosen tutor pada satu periode
# akademik. Menjadi dasar "mahasiswa bimbingan" tutor di Dashboard Analitik
# dan penyaring event asesmen blok (Fase 25). Blok masih teks bebas —
# jejak-lite sengaja tanpa Curriculum Blueprint.
class TutorialEnrollment < ApplicationRecord
  belongs_to :user # mahasiswa
  belongs_to :tutor, class_name: "User", optional: true
  belongs_to :academic_period

  validates :block_name, presence: true
  validates :block_name, uniqueness: { scope: %i[user_id academic_period_id], message: "sudah terdaftar untuk mahasiswa ini pada periode tersebut" }
  validate :end_date_after_start_date

  scope :active, -> { where(active: true) }
  scope :for_student, ->(user) { where(user: user) }
  scope :for_tutor, ->(user) { where(tutor: user) }
  scope :ordered, -> { order(active: :desc, start_date: :desc, block_name: :asc) }

  def status_label
    active? ? "Aktif" : "Selesai"
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "harus setelah atau sama dengan tanggal mulai") if end_date < start_date
  end
end
