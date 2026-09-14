# frozen_string_literal: true

# Persetujuan pasien: mahasiswa menerbitkan QR dari halaman kasus, pasien
# membuka tautan di ponselnya (tanpa login) dan menjawab butir per butir.
# Jawaban tampil di halaman kasus. Satu lembar per kasus; menerbitkan ulang
# = mencabut lembar lama lalu membuat token baru.
class PatientConsent < ApplicationRecord
  ITEMS = {
    "education"   => "Data kasus saya (tanpa identitas) dipakai untuk pendidikan mahasiswa",
    "photo"       => "Foto klinis (tanpa wajah/identitas) boleh disertakan sebagai bukti",
    "publication" => "Kasus boleh dipublikasikan sebagai laporan kasus setelah dianonimkan"
  }.freeze
  RELATIONS = { "pasien" => "Pasien sendiri", "wali" => "Wali / keluarga" }.freeze

  belongs_to :clinical_case

  has_secure_token :token, length: 32

  validates :signer_relation, inclusion: { in: RELATIONS.keys }, allow_blank: true

  def signed?
    signed_at.present? && revoked_at.nil?
  end

  def revoked?
    revoked_at.present?
  end

  def pending?
    !signed? && !revoked?
  end

  def granted?(item)
    signed? && ActiveModel::Type::Boolean.new.cast(items[item.to_s]) == true
  end

  def sign!(answers:, signer_name:, signer_relation:)
    self.items = ITEMS.keys.index_with { |k| ActiveModel::Type::Boolean.new.cast(answers[k]) == true }
    self.signer_name = signer_name.to_s.strip
    self.signer_relation = signer_relation
    self.signed_at = Time.current
    save!
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
