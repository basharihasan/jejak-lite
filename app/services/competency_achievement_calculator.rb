# frozen_string_literal: true

# Capaian per RANAH KOMPETENSI seorang mahasiswa pada satu periode. Dua sumber
# nilai, keduanya hanya dihitung bila sudah DIPETAKAN ke ranah kompetensi:
#
#   1. Dimensi ujian — mata uji CBT / station OSCE (AssessmentDimension).
#   2. Pertanyaan rubrik penguji (AssessmentFormField), mis. satu kriteria
#      "Penalaran klinis" pada rubrik SOCA.
#
# Aturan yang sengaja dipegang:
#   - yang belum dipetakan diabaikan; lebih baik kosong daripada salah atribusi;
#   - pemetaan ke sub-kompetensi naik ke ranah induknya, supaya radar tetap
#     berbicara pada tingkat ranah;
#   - satu periode saja — membandingkan antar periode menyesatkan karena
#     komposisi alat ukurnya berganti.
class CompetencyAchievementCalculator
  Row = Struct.new(:item, :percentage, :dimension_count, :sources, keyword_init: true)
  Contribution = Struct.new(:item, :percentage, :weight, :source, keyword_init: true)

  def initialize(student:, period:)
    @student = student
    @period = period
  end

  def call
    return [] if @period.nil?

    contributions = dimension_contributions + rubric_contributions
    return [] if contributions.empty?

    contributions.group_by { |c| root_of(c.item) }.filter_map do |item, rows|
      weighted = rows.sum { |c| c.percentage * c.weight }
      total_weight = rows.sum(&:weight)
      next if total_weight.zero?

      Row.new(
        item: item,
        percentage: (weighted / total_weight).round(1),
        dimension_count: rows.size,
        sources: rows.map(&:source).uniq
      )
    end.sort_by { |row| row.item.position }
  end

  private

  # ── Sumber 1: nilai per dimensi ujian ──
  def dimension_contributions
    AssessmentDimensionScore
      .joins(assessment_instance: :assessment_event)
      .where(assessment_instances: { student_id: @student.id, status: "scored" })
      .where(assessment_events: { academic_period_id: @period.id })
      .includes(assessment_dimension: :competency_item, assessment_instance: :assessment_event)
      .filter_map do |row|
        next if row.competency_item.nil?

        percentage = row.percentage
        next if percentage.nil?

        Contribution.new(item: row.competency_item, percentage: percentage, weight: row.weight.to_f,
                         source: "#{row.assessment_instance.assessment_event.name} — #{row.assessment_dimension.name}")
      end
  end

  # ── Sumber 2: jawaban rubrik penguji yang pertanyaannya dipetakan ──
  def rubric_contributions
    AssessmentFormAnswer
      .joins(assessment_form_submission: { assessment_instance: :assessment_event })
      .where(assessment_instances: { student_id: @student.id, status: "scored" })
      .where(assessment_events: { academic_period_id: @period.id })
      .includes(:assessment_form_field, assessment_form_submission: { assessment_instance: :assessment_event })
      .filter_map do |answer|
        field = answer.assessment_form_field
        next if field.nil? || field.competency_item_id.nil? || !field.scorable?

        normalized = answer.numeric_value
        next if normalized.nil?

        Contribution.new(item: field.competency_item, percentage: (normalized * 100).round(1), weight: field.weight.to_f,
                         source: "#{answer.assessment_form_submission.assessment_instance.assessment_event.name} — #{field.label}")
      end
  end

  # Dimensi/pertanyaan boleh dipetakan ke sub-kompetensi; capaian tetap
  # dilaporkan pada ranah induknya agar radar tidak pecah menjadi puluhan sumbu.
  def root_of(item)
    item.parent || item
  end
end
