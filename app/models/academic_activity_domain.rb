# frozen_string_literal: true

# Tingkat 1 taksonomi Logbook Kegiatan (jejak.pro: AcademicActivityDomain),
# mis. Praktek, Belajar Mengajar, Prestasi Kemahasiswaan.
class AcademicActivityDomain < ApplicationRecord
  include TaxonomyNode

  DEFAULT_COLOR = "#94a3b8"

  # Urutan deklarasi penting: pemeriksaan restrict berjalan SEBELUM subdomain
  # ikut dihapus, jadi domain yang sudah dipakai kegiatan tidak terhapus
  # separuh jalan.
  has_many :activity_logs, dependent: :restrict_with_error
  has_many :academic_activity_subdomains, -> { order(:position, :id) },
           dependent: :destroy, inverse_of: :academic_activity_domain

  normalizes :color_code, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :icon, with: ->(value) { value.to_s.strip.presence }

  validates :name, uniqueness: { case_sensitive: false }
  validates :color_code, format: { with: /\A#\h{6}\z/, message: "harus berformat #RRGGBB" }, allow_blank: true

  def color
    color_code.presence || DEFAULT_COLOR
  end

  private

  def siblings
    self.class.all
  end
end
