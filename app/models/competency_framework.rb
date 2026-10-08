# frozen_string_literal: true

class CompetencyFramework < ApplicationRecord
  has_many :competency_items, -> { order(:position) }, dependent: :destroy, inverse_of: :competency_framework
  # Diperiksa sebelum simpul-simpulnya dihapus (lihat CompetencyItem).
  before_destroy :ensure_unused_by_entrustment, prepend: true

  validates :name, presence: true

  def domains
    competency_items.where(parent_id: nil)
  end

  private

  def ensure_unused_by_entrustment
    return unless EntrustmentDecision.exists?(competency_item_id: competency_items.select(:id))

    errors.add(:base, "sudah dipakai pada keputusan entrustment (Peta EPA) mahasiswa")
    throw :abort
  end
end
