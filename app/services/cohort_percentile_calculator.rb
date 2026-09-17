# frozen_string_literal: true

# Kurva persentil kohort — posisi seorang mahasiswa terhadap angkatannya pada
# satu periode akademik.
#
# Kohort = seluruh mahasiswa PSSK + PSPD (gabungan, mengikuti keputusan
# jejak.pro: pendidikan dokter satu kesinambungan), dihitung per TIPE asesmen
# supaya tidak mencampur alat ukur yang berbeda — lihat catatan
# "assessment-type-mix-shifts-per-period": membandingkan rata-rata lintas tipe
# atau lintas periode selalu menyesatkan.
#
# Penjaga privasi: persentil hanya ditampilkan bila kohort berisi minimal
# MIN_COHORT mahasiswa, agar nilai perorangan tidak bisa diterka.
class CohortPercentileCalculator
  MIN_COHORT = 3
  BANDS = [ 10, 25, 50, 75, 90 ].freeze

  def initialize(student:, period:)
    @student = student
    @period = period
  end

  # [{ type:, label:, my_percentage:, percentile:, bands: {10=>..,25=>..}, cohort_size: }]
  def call
    return [] if @period.nil?

    rows = AssessmentInstance.scored.in_period(@period)
                             .joins(:assessment_event, student: :study_program)
                             .includes(:assessment_event)
                             .to_a
    return [] if rows.empty?

    rows.group_by(&:assessment_type).filter_map do |type, instances|
      by_student = instances.group_by(&:student_id)
      values = by_student.transform_values { |list| list.filter_map(&:percentage).max }.compact
      next if values.size < MIN_COHORT

      mine = values[@student.id]
      next if mine.nil?

      sorted = values.values.sort
      {
        type: type,
        label: AssessmentEvent::TYPES.dig(type, 0) || type,
        my_percentage: mine,
        cohort_size: sorted.size,
        percentile: percentile_rank(sorted, mine),
        bands: BANDS.index_with { |b| percentile_value(sorted, b) }
      }
    end
  end

  private

  def percentile_rank(sorted, value) = CohortStats.percentile_rank(sorted, value)
  def percentile_value(sorted, pct) = CohortStats.percentile_value(sorted, pct)
end
