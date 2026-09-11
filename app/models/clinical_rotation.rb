# frozen_string_literal: true

# Versi MINIMAL Rotasi Klinis — cukup untuk menampilkan jadwal ke mahasiswa
# dan jadi data pendukung DOPS/Mini-CEX (Fase 8). Bukan modul penjadwalan
# penuh: wahana cuma teks bebas (institution_name), tanpa Institution model.
class ClinicalRotation < ApplicationRecord
  belongs_to :user # mahasiswa
  belongs_to :academic_period
  belongs_to :preceptor, class_name: "User", optional: true

  validates :station_name, :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :for_student, ->(user) { where(user: user) }
  scope :for_preceptor, ->(user) { where(preceptor: user) }
  scope :upcoming, -> { where("start_date > ?", Date.current).order(:start_date) }
  scope :ongoing, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :past, -> { where("end_date < ?", Date.current).order(start_date: :desc) }
  scope :chronological, -> { order(:start_date) }

  def status
    if start_date > Date.current then "akan_datang"
    elsif end_date < Date.current then "selesai"
    else "berlangsung"
    end
  end

  def status_label
    { "akan_datang" => "Akan Datang", "berlangsung" => "Sedang Berlangsung", "selesai" => "Selesai" }.fetch(status)
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "harus setelah atau sama dengan tanggal mulai") if end_date < start_date
  end
end
