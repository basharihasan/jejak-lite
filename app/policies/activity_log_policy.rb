# frozen_string_literal: true

# Logbook Kegiatan (kegiatan non-kasus: kuliah, tutorial, jaga, dsb.) —
# meniru pola ClinicalCasePolicy: pemilik & pengajar boleh melihat, hanya
# pengajar (bukan pemilik sendiri) yang boleh memverifikasi.
class ActivityLogPolicy < ApplicationPolicy
  def show?
    owner? || user.can_verify_clinical_cases?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def verify?
    !owner? && user.can_verify_clinical_cases? && !record.verified?
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
