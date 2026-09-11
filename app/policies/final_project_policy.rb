# frozen_string_literal: true

class FinalProjectPolicy < ApplicationPolicy
  def show?
    owner? || supervisor? || user.instructor?
  end

  def create?
    user.has_role?("mahasiswa") || user.has_role?("admin")
  end
  alias new? create?

  def update?
    owner? || supervisor? || user.has_role?("admin")
  end
  alias edit? update?

  def destroy?
    (owner? && record.status == "proposal") || user.has_role?("admin")
  end

  def manage_milestones?
    update?
  end

  def score?
    user.instructor?
  end

  class Scope < Scope
    # Dosen (bukan cuma pembimbing) bisa jadi penguji siapa saja, jadi
    # diberi akses lihat semua tugas akhir — bukan cuma yang dibimbingnya.
    def resolve
      if user.instructor?
        scope.all
      else
        scope.where(student: user)
      end
    end
  end

  private

  def owner?
    record.student_id == user.id
  end

  def supervisor?
    record.supervisor_id == user.id
  end
end
