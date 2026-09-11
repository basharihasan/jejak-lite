# frozen_string_literal: true

class MiniCexEvaluationPolicy < ApplicationPolicy
  def show?
    record.student_id == user.id || record.evaluator_id == user.id || user.has_role?("admin")
  end

  def create?
    user.instructor?
  end
  alias new? create?

  def update?
    record.evaluator_id == user.id || user.has_role?("admin")
  end
  alias edit? update?

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      if user.has_role?("admin")
        scope.all
      else
        scope.where("student_id = :id OR evaluator_id = :id", id: user.id)
      end
    end
  end
end
