# frozen_string_literal: true

# Posisi satu percobaan terhadap kohort ujian yang sama + profil per dimensi
# (radar "Skor Kamu / Rerata Kohort / P90 Kohort" ala halaman nilai
# jejak.pro). Kohort = semua mahasiswa yang sudah dinilai pada event ini,
# satu nilai wakil (tertinggi) per mahasiswa.
#
# Dimensi dikelompokkan per kategori tersimpan (impor Glide: Area Kompetensi,
# Sistem Organ, …) atau bila namanya memakai pola "Kategori: Nama" (mis.
# "Siklus Kehidupan: Dewasa"); tanpa keduanya semua dimensi masuk satu radar. Semua angka dalam persen supaya dimensi dengan
# skala berbeda tetap sebanding.
class AssessmentCohortProfile
  MIN_COHORT = CohortPercentileCalculator::MIN_COHORT
  DEFAULT_GROUP = "Semua Dimensi"

  Position = Struct.new(:my_percentage, :mean, :p90, :percentile, :cohort_size, keyword_init: true)
  Group = Struct.new(:name, :labels, :mine, :mean, :p90, keyword_init: true) do
    def size = labels.size
  end

  def initialize(instance)
    @instance = instance
    @event = instance.assessment_event
  end

  # nil bila percobaan belum dinilai atau kohort terlalu kecil (privasi).
  def position
    return @position if defined?(@position)

    mine = @instance.percentage
    values = cohort_percentages
    @position = if mine.nil? || values.size < MIN_COHORT
      nil
    else
      sorted = values.values.sort
      Position.new(my_percentage: mine, mean: CohortStats.mean(sorted), p90: CohortStats.percentile_value(sorted, 90),
                   percentile: CohortStats.percentile_rank(sorted, mine), cohort_size: sorted.size)
    end
  end

  # [Group] — kosong bila percobaan ini tidak punya nilai per dimensi.
  def groups
    return @groups if defined?(@groups)

    my_scores = @instance.assessment_dimension_scores.includes(:assessment_dimension).index_by(&:assessment_dimension_id)
    return @groups = [] if my_scores.empty?

    cohort = cohort_dimension_percentages
    @groups = @event.assessment_dimensions.select { |d| my_scores.key?(d.id) }
                    .group_by { |d| category_of(d) }
                    .map do |name, dims|
      cohort_ok = cohort_instance_ids.size >= MIN_COHORT
      Group.new(
        name: name,
        labels: dims.map { |d| display_name(d) },
        mine: dims.map { |d| my_scores[d.id].percentage || 0 },
        mean: cohort_ok ? dims.map { |d| (v = cohort[d.id]) && v.any? ? CohortStats.mean(v) : nil } : nil,
        p90: cohort_ok ? dims.map { |d| (v = cohort[d.id]) && v.any? ? CohortStats.percentile_value(v.sort, 90) : nil } : nil
      )
    end
  end

  private

  # { student_id => persentase wakil }
  def cohort_percentages
    @cohort_percentages ||= @event.assessment_instances.scored.to_a.group_by(&:student_id)
                                  .transform_values { |list| list.filter_map(&:percentage).max }.compact
  end

  # id percobaan wakil (nilai tertinggi) tiap mahasiswa — dimensi kohort
  # diambil dari percobaan yang sama dengan nilai wakilnya.
  def cohort_instance_ids
    @cohort_instance_ids ||= @event.assessment_instances.scored.to_a.group_by(&:student_id)
                                   .values.filter_map { |list| list.select(&:score).max_by(&:score)&.id }
  end

  # { dimension_id => [persentase, ...] } dari seluruh percobaan wakil kohort.
  def cohort_dimension_percentages
    AssessmentDimensionScore.where(assessment_instance_id: cohort_instance_ids)
                            .includes(:assessment_dimension)
                            .group_by(&:assessment_dimension_id)
                            .transform_values { |rows| rows.filter_map(&:percentage) }
  end

  # Kategori tersimpan (impor Glide) didahulukan; selain itu pola
  # "Kategori: Nama" pada nama dimensi.
  def category_of(dimension)
    return dimension.category_label if dimension.category.present?

    dimension.name.include?(":") ? dimension.name.split(":", 2).first.strip : DEFAULT_GROUP
  end

  def display_name(dimension)
    return dimension.name if dimension.category.present?

    dimension.name.include?(":") ? dimension.name.split(":", 2).last.strip : dimension.name
  end
end
