# frozen_string_literal: true

# Seluruh Form Builder — termasuk membuka dan mengisi formulir — hanya untuk
# kaprodi dan admin. Penguji tetap mengisi rubrik template lewat Lembar
# Penguji (ExaminerEvaluationsController), yang tidak melewati policy ini.
class AssessmentFormTemplatePolicy < ApplicationPolicy
  def manage?
    user.can_manage_assessment_forms?
  end

  def index?
    manage?
  end

  def show?
    manage?
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
