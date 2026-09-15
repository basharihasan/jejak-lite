# frozen_string_literal: true

namespace :migration do
  desc "Ekspor seluruh data jejak-lite sebagai paket migrasi ke jejak.pro (DIR=tmp/migrasi INCLUDE_PATIENT_IDENTITY=false)"
  task export: :environment do
    dir = ENV["DIR"].presence || Rails.root.join("tmp", "migrasi-jejak-pro-#{Time.current.strftime('%Y%m%d-%H%M')}").to_s
    include_identity = ActiveModel::Type::Boolean.new.cast(ENV["INCLUDE_PATIENT_IDENTITY"]) || false

    puts "Mengekspor ke #{dir}#{include_identity ? ' (TERMASUK identitas pasien)' : ' (tanpa identitas pasien)'}..."
    exporter = MigrationExporter.new(dir: dir, include_patient_identity: include_identity).call

    puts "\nSelesai. Isi paket:"
    exporter.summary.sort.each { |name, count| puts format("  %-52s %6d baris", name, count) }
    puts "\nBaca #{File.join(dir, 'PANDUAN_MIGRASI.md')} untuk urutan impor di jejak.pro."
    unless include_identity
      puts "Catatan: identitas pasien TIDAK diikutkan. Ulangi dengan INCLUDE_PATIENT_IDENTITY=true bila memang perlu dipindahkan."
    end
  end

  desc "Periksa kesiapan data sebelum migrasi (tanpa mengubah apa pun)"
  task check: :environment do
    problems = []

    no_email = User.where(email: [ nil, "" ]).count
    problems << "#{no_email} pengguna tanpa email — importer jejak.pro mencocokkan lewat email" if no_email.positive?

    no_identifier = User.joins(:roles).where(roles: { code: "mahasiswa" }).where(identifier_number: [ nil, "" ]).distinct.count
    problems << "#{no_identifier} mahasiswa tanpa NPM — rotasi klinik dicocokkan lewat NPM atau email" if no_identifier.positive?

    no_prodi = User.joins(:roles).where(roles: { code: "mahasiswa" }).where(study_program_id: nil).distinct.count
    problems << "#{no_prodi} mahasiswa tanpa program studi" if no_prodi.positive?

    unmapped_dimensions = AssessmentDimension.where(competency_item_id: nil).count
    problems << "#{unmapped_dimensions} dimensi ujian belum dipetakan ke ranah kompetensi" if unmapped_dimensions.positive?

    unmapped_fields = AssessmentFormField.scorable.where(competency_item_id: nil).count
    problems << "#{unmapped_fields} pertanyaan rubrik bernilai belum dipetakan ke ranah kompetensi" if unmapped_fields.positive?

    no_period = ClinicalRotation.where(academic_period_id: nil).count
    problems << "#{no_period} rotasi tanpa periode akademik — kolom Periode wajib di importer jejak.pro" if no_period.positive?

    if problems.empty?
      puts "Siap migrasi: tidak ada masalah yang menghambat impor di jejak.pro."
    else
      puts "Perlu dibereskan dulu (tidak menghentikan ekspor, tetapi menyulitkan impor):"
      problems.each { |problem| puts "  - #{problem}" }
    end

    puts "\nRingkasan data:"
    {
      "Pengguna" => User.count, "Mahasiswa" => User.joins(:roles).where(roles: { code: "mahasiswa" }).distinct.count,
      "Kasus klinis" => ClinicalCase.count, "Baris resep" => PrescriptionItem.count,
      "Logbook kegiatan" => ActivityLog.count, "Rotasi klinik" => ClinicalRotation.count,
      "Event asesmen" => AssessmentEvent.count, "Nilai asesmen" => AssessmentInstance.count,
      "Nilai per dimensi" => AssessmentDimensionScore.count, "Rubrik" => AssessmentFormTemplate.count,
      "Keputusan entrustment" => EntrustmentDecision.count
    }.each { |label, count| puts format("  %-24s %6d", label, count) }
  end
end
