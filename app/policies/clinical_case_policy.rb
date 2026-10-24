# frozen_string_literal: true

class ClinicalCasePolicy < ApplicationPolicy
  # Draf belum diajukan ke pembimbing, jadi hanya pemiliknya (dan admin) yang
  # melihatnya; pengajar lain baru melihat kasus sejak dikirim.
  def show?
    owner? || user.has_role?("admin") || (user.can_verify_clinical_cases? && record.status != "draft")
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
  # boleh memverifikasi kasus miliknya sendiri. Kasus yang menandai
  # pembimbing hanya boleh diverifikasi pembimbing itu, bukan pengajar lain.
  def verify?
    !owner? && user.can_verify_clinical_cases? && record.status == "submitted" && assigned_verifier?
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

  # Pembimbing kasus melihat identitas pasien tanpa Break Glass walau Privacy
  # Mode menyala; pengajar lain dan pemilik kasus tetap lewat Break Glass.
  def view_patient_identity?
    show? && !owner? && record.supervised_by?(user)
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

  def assigned_verifier?
    record.supervisor_id.nil? || record.supervisor_id == user.id
  end
end
