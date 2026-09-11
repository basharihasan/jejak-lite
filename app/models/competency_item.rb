# frozen_string_literal: true

class CompetencyItem < ApplicationRecord
  belongs_to :competency_framework
  belongs_to :parent, class_name: "CompetencyItem", optional: true, inverse_of: :children
  has_many :children, -> { order(:position) }, class_name: "CompetencyItem", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :competency_milestones, dependent: :destroy
  has_many :assessment_blueprint_mappings, dependent: :destroy
  has_many :activity_log_competency_tags, dependent: :destroy

  validates :title, presence: true

  before_create :assign_position

  def domain?
    parent_id.nil?
  end

  private

  def assign_position
    siblings = parent_id ? CompetencyItem.where(parent_id: parent_id) : competency_framework.domains
    self.position = (siblings.maximum(:position) || 0) + 1
  end
end
