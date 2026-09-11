# frozen_string_literal: true

# Riwayat audit trail verifikasi kasus klinis — satu baris per transisi
# (submitted/verified/revision_requested), bukan satu kolom yang tertimpa
# tiap kali seperti sebelumnya. Meniru pola CaseVerificationComment JEJAK
# asli (tanpa rubrik terstruktur, cukup teks bebas + author + jenis aksi).
class CaseVerificationComment < ApplicationRecord
  ACTIONS = {
    "submitted" => "Dikirim untuk Verifikasi",
    "verified" => "Diverifikasi",
    "revision_requested" => "Diminta Revisi"
  }.freeze

  belongs_to :clinical_case
  belongs_to :user

  validates :action, inclusion: { in: ACTIONS.keys }

  scope :chronological, -> { order(:created_at) }

  def action_label
    ACTIONS.fetch(action, action)
  end
end
