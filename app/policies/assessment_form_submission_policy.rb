# frozen_string_literal: true

class AssessmentFormSubmissionPolicy < ApplicationPolicy
  def show?
    record.respondent_id == user.id || record.subject_user_id == user.id || user.can_manage_assessment_forms?
  end

  class Scope < Scope
    def resolve
      if user.can_manage_assessment_forms?
        scope.all
      else
        scope.where("respondent_id = :id OR subject_user_id = :id", id: user.id)
      end
    end
  end
end
