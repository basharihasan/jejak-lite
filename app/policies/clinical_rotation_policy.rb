# frozen_string_literal: true

class ClinicalRotationPolicy < ApplicationPolicy
  def show?
    record.user_id == user.id || record.preceptor_id == user.id || user.has_role?("admin")
  end

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
        scope.where("user_id = :id OR preceptor_id = :id", id: user.id)
      end
    end
  end
end
