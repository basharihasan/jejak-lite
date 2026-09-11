# frozen_string_literal: true

class CompetencyMilestonePolicy < ApplicationPolicy
  def create?
    user.has_role?("admin")
  end
  alias destroy? create?
end
