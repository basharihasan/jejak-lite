# frozen_string_literal: true

class AssessmentBlueprintMappingPolicy < ApplicationPolicy
  def create?
    user.has_role?("admin")
  end
  alias destroy? create?
end
