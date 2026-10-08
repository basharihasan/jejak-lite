# frozen_string_literal: true

# Merangkum station OSCE menjadi nilai percobaan (AssessmentInstance), massal:
#   - tiap dimensi klinis = rata-rata skor 0–3 dari station yang menilainya
#     (mengisi radar & Peta Kompetensi lewat pemetaan dimensinya);
#   - nilai = rata-rata nilai checklist station × nilai maksimum event;
#   - penguji = penguji tunggal bila semua station dinilai orang yang sama.
# Percobaan tanpa station (atau tanpa satu pun nilai checklist) kembali
# "Terdaftar".
#
# Dipakai sekali di akhir impor dan saat rollback — satu kueri per tahap,
# bukan per mahasiswa, supaya berkas belasan ribu baris tetap selesai dalam
# satu permintaan.
class OsceStationSummary
  KEYS = OsceStationScore::DIMENSIONS.keys.freeze
  BATCH = 1000
  UPDATED_COLUMNS = %i[status source max_score score examiner_id scored_at updated_at].freeze

  def self.refresh!(instance_ids)
    new(instance_ids).refresh!
  end

  def initialize(instance_ids)
    @instance_ids = Array(instance_ids).map(&:to_i).uniq
  end

  def refresh!
    return if @instance_ids.empty?

    instances = AssessmentInstance.where(id: @instance_ids).includes(:assessment_event).to_a
    stations = OsceStationScore.where(assessment_instance_id: @instance_ids)
                               .pluck(:assessment_instance_id, :scores, :checklist_score, :examiner_id, :assessed_at)
                               .group_by(&:first)
    dimensions = AssessmentDimension.where(assessment_event_id: instances.map(&:assessment_event_id).uniq, code: KEYS)
                                    .group_by(&:assessment_event_id)
    now = Time.current
    dimension_rows = []
    instance_rows = []

    instances.each do |instance|
      rows = stations.fetch(instance.id, [])
      dimensions.fetch(instance.assessment_event_id, []).each do |dimension|
        values = rows.filter_map { |row| row[1].to_h[dimension.code] }.map(&:to_f)
        next if values.empty?

        dimension_rows << { assessment_instance_id: instance.id, assessment_dimension_id: dimension.id,
                            score: (values.sum / values.size).round(2), created_at: now, updated_at: now }
      end
      # Kolom wajib ikut supaya baris upsert sah; yang diperbarui hanya
      # UPDATED_COLUMNS.
      instance_rows << instance.attributes.slice(*%w[id assessment_event_id student_id attempt_number created_at])
                               .merge(summary_attributes(instance, rows).stringify_keys, "updated_at" => now)
    end

    AssessmentInstance.transaction do
      AssessmentDimensionScore.where(assessment_instance_id: @instance_ids,
                                     assessment_dimension_id: dimensions.values.flatten.map(&:id)).delete_all
      dimension_rows.each_slice(BATCH) { |slice| AssessmentDimensionScore.insert_all(slice) }
      instance_rows.each_slice(BATCH) do |slice|
        AssessmentInstance.upsert_all(slice, unique_by: :id, update_only: UPDATED_COLUMNS, record_timestamps: false)
      end
    end
  end

  private

  def summary_attributes(instance, rows)
    # Kunci yang sama di kedua cabang — upsert_all menuntut baris seragam.
    max = instance.assessment_event.max_score.to_f
    checklist = rows.filter_map { |row| row[2] }.map(&:to_f)
    if checklist.empty?
      return { status: "registered", source: "manual", max_score: max, score: nil, examiner_id: nil, scored_at: nil }
    end

    examiners = rows.map { |row| row[3] }.uniq
    { status: "scored", source: "import", max_score: max,
      score: ((checklist.sum / checklist.size) / 100.0 * max).round(2),
      examiner_id: (examiners.size == 1 ? examiners.first : nil),
      scored_at: rows.filter_map { |row| row[4] }.max || instance.scored_at || Time.current }
  end
end
