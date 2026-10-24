# frozen_string_literal: true

# Riwayat audit trail verifikasi kasus klinis — satu baris per transisi
# (submitted/verified/revision_requested), bukan satu kolom yang tertimpa
# tiap kali seperti sebelumnya. Meniru pola CaseVerificationComment JEJAK
# asli (tanpa rubrik terstruktur, cukup teks bebas + author + jenis aksi).
class CaseVerificationComment < ApplicationRecord
  ACTIONS = {
    "submitted" => "Dikirim untuk Verifikasi",
    "verified" => "Diverifikasi",
    "revision_requested" => "Diminta Revisi",
    "rejected" => "Ditolak",
    "verification_cancelled" => "Verifikasi Dibatalkan",
    "commented" => "Komentar"
  }.freeze

  # Keputusan verifier atas kasus — dasar tab "Riwayat Verifikasi".
  REVIEW_ACTIONS = %w[verified revision_requested rejected].freeze

  # Aksi yang wajib beralasan: mahasiswa harus tahu apa yang salah.
  BODY_REQUIRED = %w[revision_requested rejected verification_cancelled commented].freeze

  belongs_to :clinical_case
  belongs_to :user

  validates :action, inclusion: { in: ACTIONS.keys }
  validates :body, presence: { message: "wajib diisi" }, if: -> { BODY_REQUIRED.include?(action) }

  scope :chronological, -> { order(:created_at) }

  def action_label
    ACTIONS.fetch(action, action)
  end
end
