# frozen_string_literal: true

class CompetencyFrameworkPolicy < ApplicationPolicy
  def index?
    true
  end
  alias show? index?

  def manage?
    user.has_role?("admin")
  end
  alias create? manage?
  alias new? manage?
  alias update? manage?
  alias edit? manage?
  alias destroy? manage?
end
