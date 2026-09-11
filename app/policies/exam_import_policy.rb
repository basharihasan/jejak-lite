# frozen_string_literal: true

class ExamImportPolicy < ApplicationPolicy
  def index?
    user.has_role?("admin")
  end
  alias show? index?
  alias create? index?
  alias new? index?
  alias destroy? index?
end
