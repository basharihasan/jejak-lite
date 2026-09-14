# frozen_string_literal: true

# Satu baris resep yang ditulis mahasiswa pada sebuah kasus klinis.
# Disimpan terstruktur (bukan teks bebas) supaya bisa ditampilkan ulang dalam
# format R/ yang benar dan ditinjau preseptor saat verifikasi.
class PrescriptionItem < ApplicationRecord
  ROUTES = [ "Oral", "Sublingual", "Topikal", "Inhalasi", "Rektal", "Intravena", "Intramuskular", "Subkutan", "Tetes mata", "Tetes telinga" ].freeze

  belongs_to :clinical_case

  validates :medication_name, presence: { message: "harus diisi pada baris resep yang sudah terisi sebagian" }

  before_create :assign_position

  scope :ordered, -> { order(:position, :id) }

  # Baris dianggap kosong bila mahasiswa belum mengisi apa pun — baris seperti
  # ini dibuang diam-diam (lihat ClinicalCase#prescription_items_attributes=),
  # bukan menggagalkan penyimpanan kasus.
  def blank_row?
    %i[medication_name strength dosage_form quantity signa route notes].all? { |attr| public_send(attr).blank? }
  end

  # Baris inscriptio/praescriptio: "R/ Parasetamol tab 500 mg No. X"
  def prescription_line
    obat = [ medication_name, dosage_form_abbr, strength ].compact_blank.join(" ")
    jumlah = quantity.presence && "No. #{quantity}"
    [ "R/", obat, jumlah ].compact_blank.join(" ")
  end

  # Baris signatura: "S 3 dd tab I p.c."
  def signa_line
    return nil if signa.blank?

    signa.to_s.strip.match?(/\AS\b/i) ? signa.to_s.strip : "S #{signa.to_s.strip}"
  end

  def dosage_form_abbr
    MedicationDefinition.new(dosage_form: dosage_form).dosage_form_abbr
  end

  private

  def assign_position
    self.position = (clinical_case&.prescription_items&.maximum(:position) || 0) + 1
  end
end
