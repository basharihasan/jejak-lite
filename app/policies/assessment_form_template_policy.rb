# frozen_string_literal: true

class AssessmentFormTemplatePolicy < ApplicationPolicy
  def manage?
    user.has_role?("admin")
  end

  def create?
    manage?
  end
  alias new? create?

  def update?
    manage?
  end
  alias edit? update?

  def destroy?
    manage?
  end
end
