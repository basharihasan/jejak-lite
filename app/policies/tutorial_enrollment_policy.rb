# frozen_string_literal: true

class TutorialEnrollmentPolicy < ApplicationPolicy
  def create?
    user.has_role?("admin")
  end
  alias new? create?

  def update?
    create?
  end
  alias edit? update?

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user.has_role?("admin")
        scope.all
      else
        scope.where("user_id = :id OR tutor_id = :id", id: user.id)
      end
    end
  end
end
