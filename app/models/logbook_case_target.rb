# frozen_string_literal: true

# Target volume kasus logbook per prodi × jenis fasilitas (FKTP = pelayanan
# primer, FKRTL = rumah sakit). Bila academic_period kosong, target berlaku
# umum untuk prodi itu. Dipakai kartu "Pemenuhan Target Kasus" di Kasus Klinis.
class LogbookCaseTarget < ApplicationRecord
  FACILITY_TYPES = { "fktp" => "FKTP (Pelayanan Primer)", "fkrtl" => "FKRTL (Rumah Sakit)" }.freeze

  belongs_to :study_program
  belongs_to :academic_period, optional: true

  validates :facility_type, inclusion: { in: FACILITY_TYPES.keys }
  validates :target_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :facility_type, uniqueness: { scope: %i[study_program_id academic_period_id], message: "sudah punya target untuk prodi & periode ini" }

  scope :ordered, -> { order(:study_program_id, :academic_period_id, :facility_type) }

  def facility_label
    FACILITY_TYPES.fetch(facility_type, facility_type)
  end

  # Target yang berlaku untuk seorang mahasiswa: periode aktif (yang memuat
  # hari ini) diutamakan, lalu target umum prodi.
  def self.applicable_for(user, on: Date.current)
    return [] if user.study_program.nil?

    period_ids = AcademicPeriod.where("start_date <= ? AND end_date >= ?", on, on).pluck(:id)
    specific = where(study_program: user.study_program, academic_period_id: period_ids)
    general  = where(study_program: user.study_program, academic_period_id: nil)
    FACILITY_TYPES.keys.filter_map { |ft| specific.find_by(facility_type: ft) || general.find_by(facility_type: ft) }
  end
end
