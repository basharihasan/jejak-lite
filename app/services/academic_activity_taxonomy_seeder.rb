# frozen_string_literal: true

# Taksonomi bawaan Logbook Kegiatan — disalin dari struktur jejak.pro (bukan
# dari seed jejak.pro: di sana "Tutorial" dkk. adalah SUBDOMAIN langsung di
# bawah "Belajar Mengajar", sedangkan seed lamanya menaruhnya satu tingkat
# lebih dalam). Domain buatan institusi di jejak.pro (mis. "share my story")
# sengaja tidak ikut; admin menambahnya sendiri lewat menu Domain Kegiatan
# Akademik.
#
# Hanya mengisi basis data yang BELUM punya domain sama sekali. Domain yang
# dihapus admin tidak dihidupkan lagi oleh deploy berikutnya (db:seed jalan
# di setiap deploy Render).
class AcademicActivityTaxonomySeeder
  PRESTASI_TEMPLATES = {
    "Kompetisi" => [
      "Juara-1 Peorangan", "Juara-2 Peorangan", "Juara-3 Perorangan", "Juara Kategori Perorangan lainnya",
      "Juara-1 Beregu", "Juara-2 Beregu", "Juara-3 Beregu", "Juara Kategori Beregu lainnya"
    ],
    "Pengakuan" => [
      "Pelatih/Wasit/Juri bersertifikat", "Pelatih/Wasit/ Juri tidak bersertifikat",
      "Nara sumber/pembicara", "Moderator", "Lainnya"
    ],
    "Penghargaan" => [
      "Tanda Jasa",
      "(grand final, peraih medali emas berdasar nilai batas)",
      "(grand final, peraih medali perak berdasar nilai batas)",
      "(grand final, peraih medali perunggu berdasar nilai batas)",
      "Piagam Partisipasi", "Penerima Hibah kompetisi"
    ],
    "Karir Organisasi" => [
      "Ketua", "Wakil Ketua", "Sekretaris", "Bendahara", "Satu tingkat dibawah pengurus harian"
    ],
    "Hasil Karya" => [
      "Patent", "Patent Sederhana", "Cipta Karya orisinal*",
      "Buku ber-ISBN penulis utama", "Buku ber-ISBN penulis kedua dst",
      "Penulis Utama/korespondensi karya ilmiah di journal yg bereputasi dan diakui",
      "Penulis kedua (bukan korespondensi) dst karya ilmiah di journal yg bereputasi dan diakui"
    ],
    "Pemberdayaan atau Aksi Kemanusiaan" => [ "Pemrakarsa / Pendiri", "Koordinator Relawan", "Relawan" ],
    "Kewirausahaan" => [ "Kewirausahaan" ]
  }.freeze

  # [nama, ikon, warna, klinis?, { subdomain => [bentuk kegiatan] }]
  DEFAULTS = [
    [ "Praktek", "briefcase", "#10b981", true, [
      "Jaga UGD", "Jaga Ruang perawatan", "Stase UGD", "Stase Ruang perawatan", "Poliklinik",
      "Kunjungan rumah", "Kunjungan layanan komunitas (posyandu, UKM)"
    ].index_with { [] } ],
    [ "Belajar Mengajar", "book-open", "#3b82f6", false, [
      "Tutorial", "Lab activity", "Clinical skills lab", "Bed-site Teaching", "Long Case", "Role Modeling",
      "Project Based Learning : Cth. penyuluhan", "Case based discussion (dengan preseptor)",
      "Expert session/Seminar Pakar", "Clinical shadowing", "Asynchronous lecture", "Magang", "ED-STAT",
      "One minute preceptor", "SNAPPS", "Aunt Minne", "Procedural skills", "Pelatihan",
      "Clinical science session (referat)", "Bimbingan dengan Academic Supervisor"
    ].index_with { [] } ],
    [ "Belajar Mandiri di Luar Jam KBM", "book", "#6366f1", false, {} ],
    [ "Evaluasi Belajar", "clipboard-document-check", "#ef4444", false, [
      "Multiple Choice Questions (MCQ)", "OSCE", "Mini CEX", "Case Based Learning", "360 degrees evaluation",
      "Direct Observasional Procedural Skill", "Project based assessment", "Quiz"
    ].index_with { [] } ],
    [ "Bimbingan", "users", "#8b5cf6", false, {} ],
    [ "Prestasi Kemahasiswaan", "trophy", "#f59e0b", false, PRESTASI_TEMPLATES ],
    [ "Riset", "beaker", "#14b8a6", false, {} ],
    [ "Pengabdian pada Masyarakat", "heart", "#f97316", false, {} ],
    [ "Penunjang", "cog", "#64748b", false, {} ],
    [ "Kemahasiswaan", "user-group", "#0ea5e9", false, {} ],
    [ "Kegiatan Lainnya", "squares-plus", "#94a3b8", false, {} ]
  ].freeze

  def self.call = new.call

  # Mengembalikan jumlah domain yang dibuat (0 bila taksonomi sudah ada).
  def call
    return 0 if AcademicActivityDomain.exists?

    AcademicActivityDomain.transaction do
      DEFAULTS.each_with_index do |(name, icon, color, clinical, subdomains), index|
        domain = AcademicActivityDomain.create!(
          name: name, icon: icon, color_code: color, is_clinical: clinical, position: index + 1
        )
        subdomains.each_with_index do |(subdomain_name, templates), sub_index|
          subdomain = domain.academic_activity_subdomains.create!(name: subdomain_name, position: sub_index + 1)
          templates.each_with_index do |template_name, template_index|
            subdomain.academic_activity_templates.create!(name: template_name, position: template_index + 1)
          end
        end
      end
    end
    DEFAULTS.size
  end
end
