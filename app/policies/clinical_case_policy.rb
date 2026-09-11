# frozen_string_literal: true

class ClinicalCasePolicy < ApplicationPolicy
  def show?
    owner? || user.can_verify_clinical_cases?
  end

  def update?
    owner? && record.editable_by_owner?
  end

  def destroy?
    owner? && record.status == "draft"
  end

  def submit?
    owner? && record.editable_by_owner?
  end

  # Bukan cuma "punya peran dosen/admin" — akun yang kebetulan juga
  # menyandang peran mahasiswa (multi-peran diperbolehkan di app ini) tidak
  # boleh memverifikasi kasus miliknya sendiri.
  def verify?
    !owner? && user.can_verify_clinical_cases? && record.status == "submitted"
  end

  def request_revision?
    verify?
  end

  class Scope < Scope
    def resolve
      if user.can_verify_clinical_cases?
        scope.all
      else
        scope.owned_by(user)
      end
    end
  end

  private

  def owner?
    record.user_id == user.id
  end
end
