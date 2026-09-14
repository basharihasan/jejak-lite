# frozen_string_literal: true

# Master obat — sumber datalist saat mahasiswa berlatih menulis resep.
# Daftar generik ala Fornas, bukan katalog harga/stok apotek.
class MedicationDefinition < ApplicationRecord
  DOSAGE_FORMS = [ "Tablet", "Kapsul", "Sirup", "Suspensi", "Salep", "Krim", "Tetes", "Supositoria", "Injeksi", "Infus" ].freeze

  validates :name, presence: true
  validates :name, uniqueness: { scope: :strength, case_sensitive: false, message: "dengan kekuatan yang sama sudah ada" }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name, :strength) }
  scope :search, ->(q) {
    q = q.to_s.strip
    next all if q.blank?

    like = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :q OR category ILIKE :q OR dosage_form ILIKE :q", q: like)
  }

  # "Parasetamol tab 500 mg" — bentuk yang dipakai di datalist dan resep.
  def label
    [ name, dosage_form_abbr, strength ].compact_blank.join(" ")
  end

  def dosage_form_abbr
    case dosage_form.to_s.downcase
    when "tablet" then "tab"
    when "kapsul" then "kaps"
    when "sirup" then "syr"
    when "suspensi" then "susp"
    when "salep" then "ung"
    when "krim" then "cr"
    when "tetes" then "gtt"
    when "supositoria" then "supp"
    when "injeksi" then "inj"
    else dosage_form.presence
    end
  end
end
