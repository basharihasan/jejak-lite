# frozen_string_literal: true

class StudyProgramPolicy < ApplicationPolicy
  def index?
    user.has_role?("admin")
  end

  def create?
    index?
  end
  alias new? create?

  def update?
    index?
  end
  alias edit? update?
end
