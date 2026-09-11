# frozen_string_literal: true

# Join model murni (bukan has_and_belongs_to_many) supaya bisa diberi index
# unik gabungan lewat migrasi biasa — mengaitkan satu entri logbook ke satu
# simpul kompetensi. Meniru activity_competency_tags JEJAK asli.
class ActivityLogCompetencyTag < ApplicationRecord
  belongs_to :activity_log
  belongs_to :competency_item

  validates :competency_item_id, uniqueness: { scope: :activity_log_id }
end
