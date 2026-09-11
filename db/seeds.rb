# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

{
  "mahasiswa" => "Mahasiswa",
  "dosen"     => "Dosen",
  "preseptor" => "Preseptor",
  "kaprodi"   => "Kaprodi",
  "admin"     => "Admin"
}.each do |code, name|
  Role.find_or_create_by!(code: code) { |role| role.name = name }
end

# Persis 2 prodi tetap — bukan hierarki Faculty/University (lihat
# IMPLEMENTATION_PLAN.md § Keputusan Arsitektur Kunci).
[ "Sarjana Kedokteran", "Profesi Dokter" ].each do |name|
  StudyProgram.find_or_create_by!(name: name)
end

# Fase 10 — Formulir Evaluasi baku: tutor evaluation, evaluasi blok,
# asesmen tambahan. Dibangun di atas Form Builder (Fase 9), bukan model
# terpisah — templat ini contoh siap pakai, admin bebas menambah/mengubah.
{
  "Evaluasi Dosen Tutor" => {
    description: "Penilaian mahasiswa terhadap dosen pembimbing kelompok tutorial.",
    anonymous: true,
    requires_subject_user: true,
    fields: [
      { label: "Dosen tutor hadir tepat waktu", field_type: "rating" },
      { label: "Dosen tutor mendorong diskusi aktif", field_type: "rating" },
      { label: "Dosen tutor memberi umpan balik yang membangun", field_type: "rating" },
      { label: "Saran perbaikan untuk dosen tutor", field_type: "textarea", required: false }
    ]
  },
  "Evaluasi Blok" => {
    description: "Penilaian mahasiswa terhadap penyelenggaraan satu blok pembelajaran.",
    anonymous: true,
    requires_subject_user: false,
    fields: [
      { label: "Tujuan pembelajaran blok tersampaikan dengan jelas", field_type: "rating" },
      { label: "Beban tugas blok ini sesuai", field_type: "rating" },
      { label: "Apakah blok ini perlu direvisi materinya?", field_type: "yes_no" },
      { label: "Masukan untuk blok ini", field_type: "textarea", required: false }
    ]
  },
  "Asesmen Tambahan" => {
    description: "Formulir umum untuk kebutuhan asesmen di luar DOPS/Mini-CEX/Progress Test.",
    anonymous: false,
    requires_subject_user: false,
    fields: [
      { label: "Nama asesmen/kegiatan", field_type: "text" },
      { label: "Catatan penilai", field_type: "textarea", required: false }
    ]
  }
}.each do |name, attrs|
  template = AssessmentFormTemplate.find_or_create_by!(name: name) do |t|
    t.description = attrs[:description]
    t.anonymous = attrs[:anonymous]
    t.requires_subject_user = attrs[:requires_subject_user]
    t.is_active = true
  end

  next if template.assessment_form_fields.any?

  attrs[:fields].each do |field_attrs|
    template.assessment_form_fields.create!(
      label: field_attrs[:label],
      field_type: field_attrs[:field_type],
      required: field_attrs.fetch(:required, true)
    )
  end
end

# Fase 13 — Kurikulum Dasar: satu peta kompetensi contoh (Standar Kompetensi
# Dokter Indonesia versi ringkas) dan satu blueprint yang mengacunya lewat
# nama ranah, bukan FK.
framework = CompetencyFramework.find_or_create_by!(name: "Standar Kompetensi Dokter Indonesia (Ringkas)") do |f|
  f.description = "Tujuh area kompetensi inti dokter layanan primer."
end

if framework.domains.none?
  {
    "Profesionalitas yang Luhur" => %w[Etika Disiplin],
    "Mawas Diri & Pengembangan Diri" => [ "Refleksi Praktik", "Belajar Sepanjang Hayat" ],
    "Komunikasi Efektif" => [ "Komunikasi Pasien", "Komunikasi Sejawat" ],
    "Pengelolaan Informasi" => [ "Rekam Medis", "Telaah Kritis" ],
    "Landasan Ilmiah Kedokteran" => [],
    "Keterampilan Klinis" => [ "Anamnesis & Pemeriksaan Fisik", "Prosedur Klinis Dasar" ],
    "Pengelolaan Masalah Kesehatan" => [ "Diagnosis", "Tata Laksana" ]
  }.each do |domain_name, sub_names|
    domain = framework.competency_items.create!(title: domain_name)
    sub_names.each { |sub_name| framework.competency_items.create!(title: sub_name, parent: domain) }
  end
end

AssessmentBlueprint.find_or_create_by!(name: "Blueprint OSCE Komprehensif") do |b|
  b.description = "Distribusi bobot stasiun OSCE akhir tahap profesi."
  b.competency_mapping = {
    "Keterampilan Klinis" => 35,
    "Komunikasi Efektif" => 20,
    "Pengelolaan Masalah Kesehatan" => 30,
    "Profesionalitas yang Luhur" => 15
  }
  b.learning_outcomes = [
    "Mampu melakukan anamnesis & pemeriksaan fisik sistematis",
    "Mampu menegakkan diagnosis banding yang rasional",
    "Mampu berkomunikasi secara empatik dengan pasien simulasi",
    "Menunjukkan perilaku profesional selama ujian"
  ]
end
