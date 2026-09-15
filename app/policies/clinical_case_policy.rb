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

  def reject?
    verify?
  end

  # Hanya verifier kasus itu sendiri atau admin yang boleh membatalkan.
  def cancel_verification?
    !owner? && record.status == "verified" &&
      (record.verified_by_id == user.id || user.has_role?("admin"))
  end

  # Pemilik dan pembimbing yang boleh membuka kasus boleh berdiskusi.
  def comment?
    show?
  end

  # Break Glass: siapa pun yang boleh membuka kasus (pemilik, pembimbing/
  # verifier, admin) boleh membukanya — tetapi selalu beralasan & tercatat.
  def break_glass?
    show?
  end

  def issue_consent?
    owner?
  end

  # CBD/Long Case hanya dari kasus milik sendiri yang sudah diajukan/diverifikasi.
  def initiate_assessment?
    owner? && %w[submitted verified].include?(record.status)
  end

  # Mini-CEX / DOPS dari kasus: aturan yang sama dengan CBD/Long Case.
  def initiate_workplace_assessment?
    initiate_assessment?
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
