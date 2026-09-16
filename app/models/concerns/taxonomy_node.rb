# frozen_string_literal: true

# Perilaku bersama tiga tingkat taksonomi kegiatan (Domain, Subdomain, Bentuk
# Kegiatan): nama wajib, status aktif, dan urutan tampil yang bisa digeser
# admin. Setiap model mendefinisikan `siblings` — baris seurutan dengannya.
module TaxonomyNode
  extend ActiveSupport::Concern

  included do
    normalizes :name, with: ->(value) { value.to_s.squish }

    validates :name, presence: true, length: { maximum: 150 }

    scope :active, -> { where(is_active: true) }
    scope :ordered, -> { order(:position, :id) }

    before_create :assign_next_position, if: -> { position.to_i.zero? }
  end

  # Tukar posisi dengan saudara di atas (:up) / di bawah (:down). Posisi
  # seluruh saudara ditulis ulang 1..n supaya nilai kembar/berlubang (baris
  # lama, impor) ikut rapi.
  def move!(direction)
    ids = siblings.ordered.pluck(:id)
    index = ids.index(id)
    target = direction.to_s == "up" ? index.to_i - 1 : index.to_i + 1
    return false if index.nil? || target.negative? || target >= ids.size

    ids[index], ids[target] = ids[target], ids[index]
    self.class.transaction do
      ids.each_with_index { |sibling_id, position| self.class.where(id: sibling_id).update_all(position: position + 1) }
    end
    true
  end

  private

  def assign_next_position
    self.position = siblings.maximum(:position).to_i + 1
  end
end
