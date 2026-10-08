# frozen_string_literal: true

class CompetencyItem < ApplicationRecord
  belongs_to :competency_framework
  belongs_to :parent, class_name: "CompetencyItem", optional: true, inverse_of: :children
  has_many :children, -> { order(:position) }, class_name: "CompetencyItem", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :competency_milestones, dependent: :destroy
  has_many :assessment_blueprint_mappings, dependent: :destroy
  has_many :activity_log_competency_tags, dependent: :destroy
  # Pemetaan dimensi ujian / pertanyaan rubrik dilepas, bukan ikut dihapus.
  has_many :assessment_dimensions, dependent: :nullify
  has_many :assessment_form_fields, dependent: :nullify
  # Keputusan entrustment (Peta EPA) adalah nilai mahasiswa: simpul yang —
  # atau yang sub-kompetensinya — sudah dipakai tidak bisa dihapus. Dijalankan
  # paling awal, sebelum anak-anaknya ikut terhapus.
  has_many :entrustment_decisions
  before_destroy :ensure_unused_by_entrustment, prepend: true

  validates :title, presence: true

  before_create :assign_position

  def domain?
    parent_id.nil?
  end

  # Id simpul ini beserta seluruh keturunannya.
  def subtree_ids
    ids = [ id ]
    level = [ id ]
    while (level = CompetencyItem.where(parent_id: level).pluck(:id)).any?
      ids.concat(level)
    end
    ids
  end

  private

  def ensure_unused_by_entrustment
    return unless EntrustmentDecision.exists?(competency_item_id: subtree_ids)

    errors.add(:base, "sudah dipakai pada keputusan entrustment (Peta EPA) mahasiswa")
    throw :abort
  end

  def assign_position
    siblings = parent_id ? CompetencyItem.where(parent_id: parent_id) : competency_framework.domains
    self.position = (siblings.maximum(:position) || 0) + 1
  end
end
