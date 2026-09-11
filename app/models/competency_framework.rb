# frozen_string_literal: true

class CompetencyFramework < ApplicationRecord
  has_many :competency_items, -> { order(:position) }, dependent: :destroy, inverse_of: :competency_framework

  validates :name, presence: true

  def domains
    competency_items.where(parent_id: nil)
  end
end
