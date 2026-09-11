# frozen_string_literal: true

class AssessmentBlueprintPolicy < ApplicationPolicy
  def index?
    user.has_role?("admin")
  end
  alias show? index?
  alias create? index?
  alias new? index?
  alias update? index?
  alias edit? index?
  alias destroy? index?
end
