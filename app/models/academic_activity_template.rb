# frozen_string_literal: true

# Tingkat 3 taksonomi — "Bentuk Kegiatan" (jejak.pro:
# AcademicActivityTemplate), mis. Juara-1 Perorangan di bawah Kompetisi.
# Opsional: form hanya menampilkannya bila subdomain terpilih punya isian.
class AcademicActivityTemplate < ApplicationRecord
  include TaxonomyNode

  belongs_to :academic_activity_subdomain
  has_many :activity_logs, dependent: :restrict_with_error

  validates :name, uniqueness: { scope: :academic_activity_subdomain_id, case_sensitive: false }

  private

  def siblings
    self.class.where(academic_activity_subdomain_id: academic_activity_subdomain_id)
  end
end
