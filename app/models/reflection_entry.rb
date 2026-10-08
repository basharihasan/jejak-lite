# frozen_string_literal: true

# Jurnal reflektif tersendiri — beda dari field `reflection` ringkas di
# ActivityLog/ClinicalCase, ini untuk tulisan reflektif yang lebih bebas,
# bisa berdiri sendiri atau ditautkan ke kegiatan/kasus tertentu.
class ReflectionEntry < ApplicationRecord
  belongs_to :user
  belongs_to :activity_log, optional: true
  belongs_to :clinical_case, optional: true

  validates :entry_date, :content, presence: true
  validate :linked_records_belong_to_owner

  scope :recent, -> { order(entry_date: :desc, created_at: :desc) }

  private

  # Id kiriman form bisa diubah: tanpa ini refleksi dapat menaut (dan
  # menampilkan judul) kegiatan/kasus milik mahasiswa lain.
  def linked_records_belong_to_owner
    errors.add(:activity_log, "bukan kegiatan milik Anda") if activity_log && activity_log.user_id != user_id
    errors.add(:clinical_case, "bukan kasus milik Anda") if clinical_case && clinical_case.user_id != user_id
  end
end
