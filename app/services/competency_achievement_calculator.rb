# frozen_string_literal: true

# Capaian per RANAH KOMPETENSI seorang mahasiswa pada satu periode, dihitung
# dari nilai per dimensi ujian (mata uji CBT / station OSCE) yang sudah
# dipetakan ke ranah kompetensi — bukan proksi rata-rata keseluruhan.
#
# Aturan yang sengaja dipegang:
#   - hanya dimensi yang SUDAH dipetakan yang dihitung; sisanya diabaikan,
#     lebih baik kosong daripada salah atribusi;
#   - nilai dimensi yang dipetakan ke sub-kompetensi ikut naik ke ranah
#     induknya, supaya radar tetap berbicara pada tingkat ranah;
#   - satu periode saja — membandingkan antar periode menyesatkan karena
#     komposisi alat ukurnya berganti.
class CompetencyAchievementCalculator
  Row = Struct.new(:item, :percentage, :dimension_count, :sources, keyword_init: true)

  def initialize(student:, period:)
    @student = student
    @period = period
  end

  # [Row(item: ranah, percentage:, dimension_count:, sources: ["CBT Blok — Penalaran Klinis", ...])]
  def call
    return [] if @period.nil?

    scores = AssessmentDimensionScore
             .joins(assessment_instance: :assessment_event)
             .where(assessment_instances: { student_id: @student.id, status: "scored" })
             .where(assessment_events: { academic_period_id: @period.id })
             .includes(assessment_dimension: :competency_item, assessment_instance: :assessment_event)
             .to_a
             .select { |row| row.competency_item.present? }
    return [] if scores.empty?

    grouped = scores.group_by { |row| root_of(row.competency_item) }

    grouped.map do |item, rows|
      weighted = 0.0
      total_weight = 0.0
      rows.each do |row|
        percentage = row.percentage
        next if percentage.nil?

        weight = row.weight.to_f
        weighted += percentage * weight
        total_weight += weight
      end
      next if total_weight.zero?

      Row.new(
        item: item,
        percentage: (weighted / total_weight).round(1),
        dimension_count: rows.size,
        sources: rows.map { |row| "#{row.assessment_instance.assessment_event.name} — #{row.assessment_dimension.name}" }.uniq
      )
    end.compact.sort_by { |row| row.item.position }
  end

  private

  # Dimensi boleh dipetakan ke sub-kompetensi; capaian tetap dilaporkan pada
  # ranah induknya agar radar tidak pecah menjadi puluhan sumbu.
  def root_of(item)
    item.parent || item
  end
end
