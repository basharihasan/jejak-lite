# frozen_string_literal: true

# Tingkat 2 taksonomi — "Subdomain / Kategori" di form Logbook Kegiatan
# (jejak.pro: AcademicActivitySubdomain), mis. Tutorial, Jaga UGD, Kompetisi.
class AcademicActivitySubdomain < ApplicationRecord
  include TaxonomyNode

  belongs_to :academic_activity_domain
  has_many :activity_logs, dependent: :restrict_with_error
  has_many :academic_activity_templates, -> { order(:position, :id) },
           dependent: :destroy, inverse_of: :academic_activity_subdomain

  validates :name, uniqueness: { scope: :academic_activity_domain_id, case_sensitive: false }

  private

  def siblings
    self.class.where(academic_activity_domain_id: academic_activity_domain_id)
  end
end
