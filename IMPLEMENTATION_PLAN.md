# Rencana Implementasi Jejak Lite

Dokumen ini adalah pelacak progres hidup — diperbarui setiap fase selesai.

## Konteks

Jejak Lite adalah aplikasi Rails 8 **terpisah total** dari JEJAK utama (PFKV2), awalnya berisi subset fitur "Dasar" dari `DAFTAR_FITUR_JEJAK.md` (repo PFKV2). Cakupannya sudah **melebar** dari sekadar "Dasar" — beberapa fitur yang diminta (Form Builder Asesmen, Tugas Akhir, Progress Test, Dashboard Analitik per peran) sebenarnya tingkat **Menengah/Lanjutan** di JEJAK, tapi dianggap perlu untuk Jejak Lite jadi aplikasi akademik yang utuh. Community Feed (media sosial internal) sudah diputuskan **tidak diperlukan** — fokus tetap pada logbook, asesmen, dan rotasi.

Dibangun ulang dari nol (bukan fork-lalu-hapus) karena `Organization`/RLS/IAM JEJAK ditenun wajib ke model-model inti JEJAK. Jejak Lite: single-tenant, tanpa mesin multi-tenant itu.

## Keputusan Arsitektur Kunci

| Keputusan | Alasan |
|---|---|
| Single-tenant, tanpa Organization/RLS/SaaS | Jejak Lite = satu instalasi = satu institusi |
| Multi-peran per akun lewat `roles`+`user_roles` sederhana | Bukan FunctionalRole/UserPersona/Capability JEJAK yang enterprise-grade |
| **Tanpa Community Feed** | Diputuskan tidak diperlukan — bukan aplikasi media sosial internal |
| `study_programs` diisi tepat 2 baris (**Sarjana Kedokteran**, **Profesi Dokter**), ditautkan ke `users` | Dipakai untuk scoping Jadwal Rotasi & Dashboard Analitik Kaprodi — bukan lagi untuk Kanal Pengumuman (sudah tidak ada) |
| Jadwal Rotasi dibangun sebagai fitur pengguna nyata, bukan data pendukung tersembunyi | Diminta eksplisit — mahasiswa perlu melihat kalender rotasinya sendiri |
| Import CBT/OSCE/Progress Test via CSV generik, skema `exam_imports`/`exam_scores` terpadu (kolom `kind`) | Bukan integrasi Glide; Progress Test numpang skema yang sama alih-alih bikin tabel baru |
| Tutor Evaluation/Evaluasi Blok/asesmen tambahan dibangun di atas **Assessment Form Builder** generik | DOPS/Mini-CEX tetap form tetap (rubrik baku); form builder untuk tipe evaluasi yang bentuknya beda-beda per institusi |
| `json` gem dikunci `~> 2.7` | json 3.x memutus dekripsi cookie sesi di Rails 8.1.3.1 |
| Kamal/Thruster/Dockerfile dilepas dari skeleton | Target deploy diputuskan di fase Deploy |

## Peran Pengguna

Seed saat ini (Fase 1): `mahasiswa`, `dosen`, `admin`.

**Perlu ditambah** sebelum Fase Dashboard Analitik: `preseptor` (pembimbing klinis lapangan) dan `kaprodi` (Ketua Program Studi). Ditambahkan saat fase yang membutuhkannya digarap.

## Roadmap & Status

### ✅ Fase 0 — Skeleton (commit `48439c4`)

### ✅ Fase 1 — Auth & Peran (commit `48439c4`)
Devise, Google OAuth opsional, `Role`/`UserRole`, Ganti Peran, Profil+avatar. *(role `preseptor`/`kaprodi` menyusul saat dibutuhkan)*

### ✅ Fase 2 — Dashboard & Navigasi Dasar (commit `479cdf6`)
Kerangka dashboard per peran, Pencarian pengguna, Panduan, `/brand`.

### ✅ Fase 2b — Dashboard Mahasiswa Berisi Data (sebagian, commit `db59080`)
Kartu "Kegiatan Bulan Ini" (hitung nyata), "Kegiatan Terbaru" (3 log terakhir), dan "Notifikasi Belum Dibaca" — semua dari data sungguhan. Agenda dari Jadwal Rotasi menyusul setelah Fase 6.

### ✅ Fase 3 — Notifikasi
`Notification` (in-app: tandai dibaca/arsipkan/tandai semua via Turbo Stream, tanpa reload halaman) + `DevicePushToken` (Web Push: kunci VAPID, service worker, tombol aktifkan/matikan) + `NotificationDeliveryJob`. Lonceng notifikasi di topbar (badge unread + pratinjau 5 terbaru) tampil di semua halaman. Locale Indonesia (`rails-i18n`) dipasang supaya `time_ago_in_words` & pesan validasi ikut berbahasa Indonesia, bukan cuma teks yang saya tulis manual. 33 test lulus.

### ✅ Fase 4 — Logbook Aktivitas Klinis & Non-Klinis + Portfolio
`ActivityLog` (klinis/non-klinis, deskripsi, refleksi, evidence files, kode pasien anonim + QR via `rqrcode`), kalender bulanan (grid HTML tanpa JS lib) + feed iCal pribadi (token, bisa di-reset). **Portfolio**: ringkasan (total, per kategori, tren 6 bulan via Chartkick, jenis kegiatan terbanyak) + ekspor CSV. 16 test baru (49 total).

### ✅ Fase 5 — Kasus Klinis Dasar
`ClinicalCase` (keluhan utama, kelompok usia/jenis kelamin pasien non-identifikasi, diagnosis, tatalaksana, poin pembelajaran, evidence files) dengan alur status draf→diajukan→terverifikasi/perlu revisi. Verifikasi memakai Pundit (`ClinicalCasePolicy`) — hanya dosen/admin, dan akun multi-peran **tidak bisa memverifikasi kasus miliknya sendiri** (celah ditemukan & ditutup saat verifikasi manual). Notifikasi otomatis ke mahasiswa saat kasus diverifikasi/diminta revisi (numpang `Notification.notify!` dari Fase 3). Portal pasien token publik **tidak diperlukan** — dihapus dari cakupan. Household/family graph ditunda.

**Catatan infrastruktur test**: `parallelize(workers: :number_of_processors, with: :threads)` bawaan Rails 8 menyebabkan deadlock Postgres nyata (thread berebut lock tabel saat reload fixture) begitu jumlah test bertambah — dimatikan (`workers: 1`) karena suite masih di bawah 3 detik serial.

### ✅ Fase 6 — Jadwal Rotasi & Periode Akademik
`StudyProgram` (2 baris tetap: Sarjana Kedokteran, Profesi Dokter — dipilih mahasiswa di Profil), `AcademicPeriod` (dikelola admin), `ClinicalRotation` (mahasiswa+preseptor opsional+periode+bagian/departemen+wahana+tanggal, status akan_datang/berlangsung/selesai dihitung dari tanggal). Pundit (`ClinicalRotationPolicy`, `AcademicPeriodPolicy`): hanya admin yang bisa menjadwalkan; mahasiswa & preseptor hanya melihat rotasi milik/dibimbingnya sendiri lewat `policy_scope`. Dashboard menampilkan widget "Rotasi Sedang Berlangsung/Berikutnya" (agenda, melengkapi janji Fase 2b). Fondasi bagi DOPS/Mini-CEX (Fase 8) dan Dashboard Analitik (Fase 15). 10 test baru (73 total). Diverifikasi manual 3 akun: admin membuat periode+rotasi → mahasiswa melihatnya di dashboard & jadwal & profil.

### ✅ Fase 7 — Modul Refleksi (Jurnal Digital)
`ReflectionEntry` (tanggal, judul opsional, isi bebas, tertaut opsional ke `ActivityLog`/`ClinicalCase`) — jurnal tersendiri, terpisah dari field `reflection` ringkas di Logbook/Kasus Klinis. CRUD kepemilikan sederhana (bukan Pundit — pola `current_user.reflection_entries.find` seperti ActivityLog/Portfolio). Topbar dirapikan dengan dropdown "Lainnya" untuk tautan yang lebih jarang dipakai (Cari, Panduan, Periode Akademik). 6 test baru (79 total). Diverifikasi manual: tulis refleksi tertaut ke kegiatan → tautannya tampil & bisa diklik balik ke kegiatan asal.

### ✅ Fase 8 — DOPS & Mini-CEX
`DopsEvaluation` (6 dimensi: persiapan/teknik/asepsis/komunikasi/profesionalisme/pasca tindakan) & `MiniCexEvaluation` (7 dimensi: anamnesis/pemeriksaan fisik/profesionalisme/clinical judgment/konseling/organisasi/kompetensi keseluruhan) — skor JSONB per dimensi skala **1–9** (meniru skala Mini-CEX standar internasional), dimensi Profesionalisme & Komunikasi **wajib** (tidak boleh N/A), meniru aturan yang baru diterapkan JEJAK asli. Logika bersama di concern `DimensionScorable` (validasi rentang, rata-rata, dsb). Pundit: hanya dosen/admin bisa membuat, hanya penilai/admin bisa menyunting, mahasiswa hanya bisa melihat miliknya sendiri. Notifikasi otomatis ke mahasiswa saat evaluasi dibuat. Halaman ringkasan gabungan `/asesmen`. 21 test baru (94 total). Diverifikasi manual: dosen menilai (1 dimensi N/A) → rata-rata benar mengecualikan N/A → mahasiswa melihat & dapat notifikasi.

### ✅ Fase 9 — Assessment Form Builder
`AssessmentFormTemplate` (nama, deskripsi, aktif/tidak, anonim, wajib-pilih-subjek) + `AssessmentFormField` (label, jenis: rating 1–5/ya-tidak/teks singkat/teks panjang, wajib/opsional, posisi otomatis) + `AssessmentFormSubmission`+`AssessmentFormAnswer` (jawaban aktual). **Digabung dengan alur pengisian penuh** (bukan cuma builder kosong) supaya tidak setengah-jadi — admin bikin formulir+pertanyaan, siapa pun mengisi, hasil bisa dilihat. Anonimitas: `respondent_visible_to?` menyembunyikan identitas pengisi dari subjek yang dinilai (admin selalu bisa lihat) — meniru pola `reveal_identity` JEJAK tanpa membangun UI reveal terpisah. Pundit: admin-only kelola formulir/pertanyaan; siapa pun bisa isi formulir aktif; lihat jawaban dibatasi pengisi/subjek/admin. 12 test baru (102 total). Diverifikasi manual: admin bikin formulir "Evaluasi Blok" + 2 pertanyaan (rating & teks) → mahasiswa mengisi → admin melihat jawaban masuk dengan nilai utuh.

### ✅ Fase 10 — Formulir Evaluasi (digabung dengan Fase 9, tuntas sekaligus)
Tiga templat baku di-seed lewat `db/seeds.rb` memakai infrastruktur Fase 9 — bukan model/kode terpisah, sesuai rencana ("didefinisikan lewat Form Builder"): **Evaluasi Dosen Tutor** (anonim, wajib pilih subjek dosen, 4 pertanyaan), **Evaluasi Blok** (anonim, tanpa subjek personal, 4 pertanyaan termasuk ya/tidak), **Asesmen Tambahan** (formulir umum non-anonim, 2 pertanyaan). Admin bebas menambah/mengubah templat lain kapan pun tanpa kode baru. Diverifikasi tampil dengan badge Anonim yang benar di index.

### ✅ Fase 11 — Tugas Akhir
`FinalProject` (mahasiswa, dosen pembimbing opsional, judul, deskripsi, status proposal/berjalan/selesai) + `FinalProjectMilestone` (checklist bertanggal, bisa ditandai selesai/dibuka lagi, deteksi terlambat) + `ExaminerScore` (skor 0–100 + umpan balik per sesi ujian, banyak penguji per proyek). Pundit (`FinalProjectPolicy`): mahasiswa mendaftarkan & mengelola miliknya sendiri, **dosen mana pun bisa melihat semua tugas akhir** (berpotensi jadi penguji, bukan cuma pembimbing), hanya instruktur yang bisa memberi skor. Notifikasi otomatis ke mahasiswa saat skor ujian baru masuk. 10 test baru (112 total). Diverifikasi manual: mahasiswa daftar TA + tambah milestone → dosen beri skor+umpan balik → rata-rata skor benar & notifikasi terkirim.

### ✅ Fase 12+14 — Progress Test & Import CBT/OSCE (digabung sekaligus)
`ExamImport` (batch impor: kind cbt/osce/progress_test, nama, pengimpor, jumlah baris, jumlah email tak dikenali) + `ExamScore` (skor+max_score per mahasiswa+tanggal, `percentage` turunan). Satu `ExamScoreImporter` (parser CSV: `email,score,exam_date,max_score`) melayani ketiga jenis ujian sekaligus — bukan tiga pipeline seperti JEJAK, dan **bukan integrasi Glide** (Jejak Lite berdiri sendiri). Admin: halaman impor + riwayat batch + hapus batch (rollback). Mahasiswa: halaman "Nilai Ujian" per jenis dengan tren grafik (Chartkick, pola sama seperti Portfolio). 8 test baru (120 total). Diverifikasi manual via HTTP sungguhan (bukan cuma test suite): unggah CSV 2 baris (1 valid + 1 email tak dikenal) → hasil impor benar (1 sukses, 1 tak dikenal terdeteksi) → mahasiswa melihat skornya di grafik.

### ✅ Fase 13 — Kurikulum Dasar
`AssessmentBlueprint` (berdiri sendiri, JSONB `competency_mapping` ranah→bobot tervalidasi harus berjumlah 100%, `learning_outcomes` array — ditulis lewat textarea "Ranah: Bobot"/satu-capaian-per-baris di UI, bukan form dinamis JS, karena tanpa FK ke CompetencyFramework meniru desain JEJAK asli). `CompetencyFramework`+`CompetencyItem` (pohon self-referential 2 level: ranah/domain lalu sub-kompetensi, posisi otomatis mengikuti urutan pembuatan). Pundit: `AssessmentBlueprintPolicy` admin-only penuh; `CompetencyFrameworkPolicy`/`CompetencyItemPolicy` — index/show terbuka untuk semua yang login (referensi bersama), kelola (tambah/hapus ranah & sub-kompetensi lewat form inline di halaman detail) admin-only. Halaman baru "Analisis Capaian Pembelajaran" (`/capaian-belajar`, `AcademicAssessmentsController`) — potret pribadi **satu periode akademik terpilih** (dropdown), menggabungkan DOPS+Mini-CEX (rata-rata skor & daftar per rotasi periode itu) dan skor ujian (dari `ExamScore`, difilter tanggal ujian dalam rentang periode) milik mahasiswa yang login saja; sengaja **tanpa tabel `academic_assessment_results` terpisah dan tanpa grafik tren antar periode** — agregasi langsung dari data yang sudah ada (DopsEvaluation/MiniCexEvaluation/ExamScore) supaya tidak ada data ganda yang bisa basi, dan tren rata-rata antar periode akademik JEJAK asli terbukti selalu menyesatkan karena jenis/bobot asesmen berganti tiap periode. 20 test baru (140 total). Diverifikasi manual via HTTP sungguhan: admin membuat peta kompetensi + tambah ranah & sub-kompetensi inline → blueprint dengan bobot 100% tampil dengan pie chart → mahasiswa (non-admin) bisa melihat peta kompetensi (read-only, ditolak saat mencoba menambah ranah — dikonfirmasi 0 baris tersimpan) → mahasiswa melihat capaian pribadinya sendiri di `/capaian-belajar`, mahasiswa lain tidak melihat data yang bukan miliknya.

### ✅ Fase 15 — Dashboard Analitik (Dosen, Preseptor, Kaprodi)
Peran `preseptor` & `kaprodi` ditambahkan ke seed (`instructor?` diperluas mencakup preseptor — kini boleh menilai DOPS/Mini-CEX/verifikasi kasus klinis, setara dosen). **Satu halaman `/analitik` (`AnalyticsController`) dengan tiga bagian kondisional**, bukan tiga controller/halaman terpisah — konsisten dengan pilar multi-peran per akun jejak-lite (satu akun bisa punya kombinasi peran apa pun, halaman menyesuaikan bagian mana yang tampil): (1) **Mahasiswa Bimbingan** untuk dosen/admin — mahasiswa yang tugas akhirnya dibimbing ATAU pernah dinilai DOPS/Mini-CEX oleh dosen ybs; (2) **Mahasiswa di Wahana Anda** untuk preseptor/admin — daftar `ClinicalRotation.for_preceptor`, dengan hitungan kegiatan logbook & DOPS/Mini-CEX selama rentang tanggal rotasi; (3) **Program Studi** untuk kaprodi/admin — seluruh mahasiswa satu `study_program` (kaprodi dikunci ke `study_program_id` miliknya sendiri via kolom yang sama dipakai mahasiswa, tanpa kolom baru; admin bebas pilih prodi mana pun lewat dropdown). Tiap baris mahasiswa menampilkan: kegiatan bulan ini, rata-rata DOPS, rata-rata Mini-CEX, rasio kasus klinis terverifikasi. Akses dijaga guard peran sederhana (bukan Pundit — halaman ini bukan milik satu model, mengikuti pola `AssessmentsController`/`AcademicAssessmentsController` yang juga tanpa Pundit untuk data lintas-model/personal). 5 test baru (145 total). Diverifikasi manual via HTTP sungguhan dengan akun dev multi-peran (dosen+preseptor+kaprodi sekaligus): ketiga bagian tampil bersamaan tanpa galat, mahasiswa yang sama muncul konsisten di ketiganya sesuai relasi aslinya; mahasiswa murni ditolak akses (dikonfirmasi lewat test otomatis).

### ✅ Fase 16 — Deploy & Poles
Target deploy: **Render** (`render.yaml` blueprint, native Ruby runtime — tanpa Docker/Kamal, konsisten dengan Gemfile yang sengaja tidak membawa gem deploy tersebut). `config/database.yml` produksi disederhanakan dari skema 4-database default Rails 8 menjadi satu `DATABASE_URL` yang dipakai bersama oleh primary/cache/queue/cable (aman karena tabel solid_* punya nama unik) — supaya cukup satu instance Postgres gratis. `config.assume_ssl`/`config.force_ssl` diaktifkan (Render mengakhiri SSL di reverse proxy). `bin/render-build.sh` menjalankan precompile aset + migrate semua role database + `db:seed`. **Data demo dipisah dari `db/seeds.rb`** ke task baru `bin/rails demo:seed` (`lib/tasks/demo.rake`, idempoten) — 7 akun contoh (admin/dosen/preseptor/kaprodi/multi-peran/2 mahasiswa) dengan data saling terhubung di semua fitur (logbook, kasus klinis, rotasi, DOPS/Mini-CEX, tugas akhir+milestone, formulir evaluasi terisi, skor ujian, refleksi) — dipisah dari seed rujukan karena berisi password contoh yang sengaja publik (`password123`), bukan data wajib aplikasi. README ditulis ulang: daftar fitur, cara menjalankan lokal, cara pakai data demo, langkah deploy Render, dan keterbatasan yang perlu diketahui (Active Storage disk lokal = hilang tiap deploy ulang di PaaS ephemeral filesystem; 4 role database sengaja berbagi 1 database fisik). Regresi penuh: 145 test tetap hijau setelah seluruh perubahan konfigurasi. Diverifikasi manual end-to-end via HTTP sungguhan dengan ketujuh akun demo — mahasiswa (17 halaman), dosen (7 halaman termasuk Dashboard Analitik & form penilaian baru), admin (7 halaman termasuk kelola kurikulum) — seluruhnya 200 OK, nol exception/500 di log server.

**Jejak Lite selesai Fase 0–16.** Seluruh fitur dari `DAFTAR_FITUR_JEJAK.md` tingkat Dasar plus perluasan yang diminta pengguna (Form Builder, Tugas Akhir, Progress Test, Dashboard Analitik per peran, Kurikulum) sudah terimplementasi, teruji (145 test), dan siap didemokan atau di-deploy.

## Fase 17-20 — Perkaya Kesenjangan dengan JEJAK Asli

Setelah dicoba, fitur jejak-lite dinilai terlalu tipis dibanding JEJAK asli untuk modul yang sama. Riset mendalam (4 agen Explore membaca source code JEJAK) menemukan kesenjangan konkret sekaligus batas yang harus dijaga: beberapa bagian JEJAK asli (`ActivityCaseDatum` 100+ kolom+PII terenkripsi+lab/radiologi, mesin kurva pertumbuhan lintas-kohort) justru terlalu berat untuk tujuan "lite" dan sengaja TIDAK dibawa. Rencana lengkap & alasan tiap keputusan ada di plan file sesi (`floofy-tickling-dahl.md`). Lihat juga bagian "Sengaja Tidak Dibawa" di bawah untuk daftar eksplisit yang dilewati.

### ✅ Fase 17 — Perkaya DOPS & Mini-CEX
**Pondasi bersama baru**: `radar_chart_controller.js` (Stimulus, panggil `window.Chart` type radar langsung — Chart.js sudah dimuat lewat Chartkick tapi Chartkick sendiri tak punya tipe radar) dan `ClinicalContextOptions` (module konstanta `CLINICAL_SETTINGS`/`AGE_GROUPS`/`CASE_COMPLEXITY`, dipakai DOPS, Mini-CEX, dan nanti Kasus Klinis Fase 18).

DOPS: `DIMENSIONS` diperluas dari 6 ke **10** meniru rubrik JEJAK asli (tambah persetujuan tindakan, analgesia/sedasi, meminta bantuan, penilaian global; `teknik`→`kemampuan_teknis`). `REQUIRED_DIMENSIONS` jadi 3 (komunikasi/profesionalisme/penilaian_global — SELALU wajib, sisanya boleh N/A). Mini-CEX: `konseling`+`kompetensi_keseluruhan` diganti `komunikasi` (dimensi numerik ke-6) + `global_rating` (field kualitatif 4-pilihan TERPISAH dari `scores`, meniru cara Mini-CEX standar menilai keseluruhan — bukan skala 1-9 lagi).

Field konteks baru di kedua model: `clinical_setting`, `patient_age_group`, `case_complexity`, `observation_minutes`, `feedback_minutes`, `video_recording_url` (tervalidasi format http/https). Form scoring diganti dari dropdown jadi **radio-card 1-9** dengan pita warna (merah 1-3/kuning 4-6/hijau 7-9, partial bersama `shared/_dimension_score_radio`) + opsi N/A untuk dimensi tak wajib; DOPS dapat `<datalist>` autocomplete nama prosedur umum.

**Status draft/submitted** (concern `DimensionScorable` diperluas): dua tombol submit ("Simpan Draf"/"Kirim Evaluasi") menyetel `status` langsung dari nama tombol yang diklik (tanpa JS) — notifikasi ke mahasiswa baru terkirim saat `submit!` (transisi ke submitted), bukan saat draf dibuat. Method `avg_dimension_scores` baru (agregat rata-rata per dimensi lintas evaluasi) — pondasi radar chart kohort di Fase 19-20. Halaman show kini menampilkan radar chart peta dimensi (di atas progress bar lama yang dipertahankan untuk angka presisi). `/asesmen` dipecah dua bagian: "Menunggu Diselesaikan" (draf milik evaluator sendiri) vs daftar submitted seperti biasa, dengan badge skor berwarna (helper baru `score_band_classes`).

14 test baru (154 total). Diverifikasi manual via HTTP sungguhan: draf dibuat → notifikasi BELUM terkirim → radar chart tampil di show dengan 10 sumbu → submit → notifikasi terkirim & status berubah → panel "Menunggu Diselesaikan" menghilang dari `/asesmen`.

**Bug ditemukan & diperbaiki saat verifikasi manual**: `options_for_select(HASH, selected)` dipanggil dengan hash `{kode => label}` di 9 tempat (field konteks klinis DOPS/Mini-CEX/Kasus Klinis) — Rails membaca Hash sebagai `{teks => value}`, jadi value & label KETUKAR (`<option value="Rawat Jalan">rawat_jalan</option>`, terbalik). Ketahuan justru karena field sudah ada dari awal, cuma isi opsinya salah arah — baru kelihatan waktu submit form sungguhan lewat curl (bukan test suite, yang cuma cek keberadaan label). Diperbaiki dengan `.invert` di semua pemanggilan; pola lama yang benar (`ActivityLog::CATEGORIES.invert` di form Logbook) dipakai sebagai rujukan konsistensi.

### ✅ Fase 18 — Perkaya Logbook & Kasus Klinis
Sadar penuh **tidak** membawa arsitektur JEJAK asli untuk kasus klinis (`ActivityLog`+`ActivityCaseDatum` 100+ kolom, PII terenkripsi, lab/radiologi/bedah/follow-up SOAP terpisah, token QR tamu) — `ClinicalCase` jejak-lite tetap satu model, cuma diperkaya, bukan dirombak arsitekturnya (lihat "Sengaja Tidak Dibawa").

**Logbook (ActivityLog)**: field baru `location` & `delivery_mode` (Luring/Daring). Tabel baru `activity_log_competency_tags` menautkan tiap entri logbook ke simpul `CompetencyItem` (Kurikulum, Fase 13) — keterkaitan lintas-modul yang sebelumnya sama sekali tidak ada, multi-select checkbox di form. Index diubah dari daftar datar jadi **timeline dikelompokkan per tanggal** + filter chip kompetensi (menyusul filter kategori yang sudah ada); kartu logbook dapat badge kompetensi & ikon refleksi.

**Kasus Klinis (ClinicalCase)**: field baru `clinical_setting`, `case_complexity` (dari `ClinicalContextOptions` bersama Fase 17), `entrustment_level` (skala 6 level meniru JEJAK: diobservasi→dibantu→supervisi langsung→supervisi tidak langsung→mandiri→mengajari junior, diisi verifier), `recommend_remediation` (flag verifier). **Kolom tunggal `verification_comment` (tertimpa tiap transisi) diganti tabel `case_verification_comments`** — riwayat audit trail lengkap satu baris per transisi (submitted/verified/revision_requested), data lama dimigrasikan otomatis sebelum kolom dihapus. `verify!`/`request_revision!`/`submit!` kini masing-masing mencatat baris riwayat. Index dapat panel statistik (breakdown status + `bar_chart` diagnosis terbanyak); show menampilkan riwayat verifikasi sebagai timeline, bukan satu blok teks.

18 test baru (160 total). Diverifikasi manual via HTTP sungguhan: catat kegiatan bertag kompetensi → muncul di timeline & lolos filter kompetensi → verifikasi kasus dengan entrustment level + flag remediasi → riwayat verifikasi bertambah baris & badge remediasi tampil → panel statistik index berubah.

### ✅ Fase 19 — Perkaya Dashboard & Dashboard Analitik
**Dashboard utama**: kartu quick-action untuk dosen/preseptor/admin — "N Evaluasi Draf Belum Dikirim" & "N Kasus Klinis Menunggu Verifikasi", masing-masing tautan langsung ke halaman terkait (bukan cuma "Langkah Berikutnya" statis). Mahasiswa dengan evaluasi DOPS/Mini-CEX submitted melihat peta kompetensi (radar chart) dimensi rata-ratanya sendiri.

**Dashboard Analitik (`/analitik`)**: (1) **badge skor berwarna** (hijau/kuning/merah, helper `score_band_classes` dari Fase 17) di ketiga tabel; (2) **sort berdasar risiko** — mahasiswa dengan rata-rata skor terendah muncul paling atas di tiap daftar (mahasiswa TANPA data sama sekali diletakkan di akhir, bukan dianggap paling berisiko — beda kondisi yang sengaja dibedakan); (3) **radar chart kohort** di bagian Program Studi (rata-rata dimensi DOPS+Mini-CEX se-prodi, muncul kalau ada data pada periode terpilih); (4) **filter periode akademik** (dropdown di header halaman) yang men-scope ketiga bagian ke rotasi/kasus/kegiatan dalam satu periode — bonus: menemukan bug laten bahwa skor draft ikut terhitung ke rata-rata (belum di-scope `.submitted`), sekalian diperbaiki.

4 test baru (164 total). Diverifikasi manual via HTTP sungguhan: dosen dengan evaluasi draft & kasus pending melihat kedua kartu quick-action di dashboard; mahasiswa dengan evaluasi submitted melihat radar kompetensinya; halaman analitik menampilkan radar kohort + badge warna + filter periode berfungsi (ganti periode → daftar & radar ikut berubah).

### ✅ Fase 20 — Perkaya Kurikulum & Kompetensi (fase terakhir Perkaya JEJAK)
**Temuan riset yang mengubah rencana**: `AssessmentBlueprint` versi lama (JSONB `competency_mapping` bebas teks) ternyata PERSIS meniru model yang sama di JEJAK asli yang SUDAH DITINGGALKAN di sana (kelas yatim, tidak dipakai controller/view manapun) — JEJAK asli pindah ke mapping berelasi FK (`AssessmentDimensionMapping`). jejak-lite ikut pindah pola yang sama.

**Blueprint ↔ Kompetensi**: tabel baru `assessment_blueprint_mappings` (FK ke `CompetencyItem` + bobot desimal, unique per pasangan) **menggantikan** `competency_mapping` JSONB — data lama dimigrasikan otomatis (cocokkan label ke `CompetencyItem.title` persis; yang tidak cocok dilewati, bukan dipaksakan) sebelum kolom lama dihapus. UI: tambah satu baris mapping (pilih kompetensi + bobot) dengan tombol hapus per baris — pola sama persis dengan form inline tambah-ranah yang sudah ada, bukan JS dinamis baru. Halaman show: `pie_chart` diganti radar chart (bobot per kompetensi).

**`CompetencyMilestone`** (tabel baru, versi ringan dari `CompetencyGrowthTarget` JEJAK asli yang punya 3 tingkat target + kurva kohort): satu target skor (1-9) per domain per periode akademik, dikelola inline dari baris domain di halaman Peta Kompetensi.

**Halaman Capaian Belajar**: tambah radar chart DOPS+Mini-CEX mahasiswa untuk periode terpilih. Untuk tiap target milestone periode itu, tampilkan badge Tercapai/Di Bawah Target — **dibandingkan dengan rata-rata KESELURUHAN DOPS+Mini-CEX mahasiswa, BUKAN skor spesifik ranah itu** (jejak-lite sengaja tidak membangun linkage skor-per-domain — tidak ada sumber data yang menghubungkan skor DOPS/Mini-CEX ke domain kompetensi tertentu secara presisi; badge ini proksi capaian umum, dilabeli jelas sebagai itu di UI, bukan diklaim presisi per-ranah). Tetap SATU periode saja, tanpa grafik tren antar-periode.

**Bug ditemukan & diperbaiki saat verifikasi manual**: menghapus `CompetencyItem` yang sudah dipakai `assessment_blueprint_mappings`/`activity_log_competency_tags` gagal dengan `ForeignKeyViolation` — asosiasi `has_many` dengan `dependent: :destroy` di sisi `CompetencyItem` belum ada untuk kedua tabel baru itu (FK constraint sendiri tidak punya `ON DELETE CASCADE`). Ditambahkan di model.

12 test baru (172 total, semua hijau). Diverifikasi manual via HTTP sungguhan: admin tambah mapping baru → total bobot & radar chart ikut berubah → hapus mapping → kembali seimbang; admin set target milestone → mahasiswa lihat badge "Tercapai" di Capaian Belajar.

**Jejak Lite selesai Fase 0-20** — seluruh siklus "Perkaya Kesenjangan dengan JEJAK Asli" (Fase 17-20) tuntas. 172 test hijau.

### ✅ Fase 21 — Wizard Kasus Klinis & Dokumentasi Klinis Lengkap
Ditambahkan setelah pengguna membandingkan langsung `localhost:3000/clinical_cases/new` dengan `jejak.pro/clinical_logbook/cases/new` sungguhan lewat screenshot — bukan dari riset source code lagi, tapi perbandingan visual nyata.

**Yang diambil dari JEJAK asli** (murni UX + data, tanpa AI): form Kasus Klinis diubah dari satu form datar panjang menjadi **wizard 4 langkah** ("Informasi Dasar" → "Anamnesis & Pemeriksaan Fisik" → "Diagnosis & Tatalaksana" → "Pembelajaran & Bukti") dengan indikator progres ala JEJAK ("Langkah X dari Y" + dot progress) — Stimulus controller baru `wizard_controller.js`, murni sisi klien (semua field tetap satu `<form>`, cuma disembunyikan pakai `[hidden]`, jadi submit akhir tetap satu POST/PATCH normal, TANPA perubahan di controller). Field klinis baru pada `ClinicalCase`: `anamnesis`, `general_condition`, `physical_examination`, `family_history` (teks bebas, meniru pemisahan dokumentasi klinis JEJAK asli — jauh lebih rinci dari sekadar `diagnosis`/`management`), dan `vital_signs` (JSONB: suhu, tekanan darah sistol/diastol, nadi, respirasi, berat, tinggi) dengan `bmi` dihitung otomatis dari berat/tinggi (method model, bukan tersimpan).

**Yang SENGAJA tidak dibawa** — semua elemen di layar JEJAK yang **berbasis AI**: dikte suara ("Voice"), "✨ Enhance" (penghalusan teks AI), "Smart PE Builder" (generator template pemeriksaan fisik AI), dan "Clinical Assistant" (chatbot mengambang) — konsisten dengan keputusan Gemfile sejak awal proyek (tanpa gem AI). Pola upload foto via paste-URL Google Drive JEJAK juga tidak ditiru — upload file langsung (`evidence_files`, sudah ada) teknisnya lebih baik (bukan tautan yang bisa kedaluwarsa).

6 test baru (176 total, semua hijau). Diverifikasi manual via HTTP sungguhan: wizard 4 langkah tampil dengan benar (`data-controller="wizard"`, 4 `[data-wizard-target="step"]`), submit satu kali membawa semua field termasuk tanda vital nested, BMI terhitung otomatis dan tampil di halaman show.

## Fase 22–26 — "Semirip mungkin dengan jejak.pro, hanya fitur 🟢"

Diputuskan 14 September 2026 setelah `DAFTAR_FITUR_JEJAK.md` v2.0 (di repo PFKV2) menetapkan **Paket Dasar = fondasi + tiga pilar**: (A) pencatatan kasus, (B) asesmen dasar PSSK & PSPD, (C) pemetaan capaian. Pilihan pengguna: lanjutkan jejak-lite (bukan salin-potong PFKV2) dan tiru tampilan jejak.pro; syarat mutlak "jangan sampai ada error" — tiap fase: test hijau + smoke test HTTP sungguhan (`tmp/smoke.sh`, login tiap akun demo, buka semua halaman sidebar).

### ✅ Fase 22 — Cangkang UI jejak.pro (sidebar, topbar, tema)
Layout diganti total meniru `app/views/layouts/application.html.erb` + `shared/_sidebar`, `_sidebar_nav`, `_nav_item`, `_topbar`, `_flash` jejak.pro: sidebar gelap `bg-slate-900` lebar 64 dengan blok brand, identitas + peran aktif + tombol Edit Profil, kotak "Cari menu" (filter sisi klien), grup navigasi berjudul kapital, accordion (Logbook, Asesmen & Evaluasi), footer Panduan/Pengaturan; sidebar geser untuk layar kecil + overlay; topbar putih lengket dengan hamburger, judul halaman (`content_for :title`), pengalih peran (select), pencarian, tombol tema, bantuan, lonceng notifikasi (dropdown beranimasi), menu akun; bilah navigasi bawah mobile. Stimulus `sidebar`, `accordion`, `notification_dropdown`, `theme_toggle`, `flash` diambil apa adanya dari jejak.pro. CSS tema jejak.pro (`--color-primary`, retrofit mode gelap `html.dark`, skala huruf `text-size-*`) disalin utuh; font Inter di-self-host di `public/vendor/fonts/inter`.

**Grup sidebar hanya yang 🟢**: Ikhtisar, Perjalanan Belajar, Asesmen, Kompetensi & Prestasi, Coaching Center (dosen/preseptor/kaprodi/admin — lencana kasus menunggu verifikasi), Konfigurasi (admin, mengikuti policy `has_role?("admin")`). Menu menyempit mengikuti **peran aktif**, bukan gabungan peran. Accordion yang memuat halaman aktif dirender terbuka dari server (bukan menunggu JS).

**Pengaturan Saya** (`/pengaturan`): kolom `users.theme_preference` (light/dark/system) & `font_size_preference` (small/normal/large), `Settings::PreferencesController#update_appearance` melayani form HTML dan fetch JSON dari tombol tema topbar. Skrip bootstrap tema di `<head>` mencegah kedipan.

**Perbaikan sampingan**: `config/locales/devise.id.yml` disalin dari jejak.pro — sebelumnya flash Devise tampil "Translation missing" karena `default_locale = :id` tanpa terjemahan Devise. Test lama `analytics_controller_test` dipersempit ke `<main>` karena `assert_no_match "/9"` tersandung kelas `bg-white/95` layout.

8 test baru (184 total, hijau). Smoke HTTP: 8 akun demo × 26 halaman, nol 500. Screenshot headless Chrome (`tmp/shot_*.png`) dibandingkan langsung dengan cangkang jejak.pro.

### ✅ Fase 23 — Fondasi: prodi PSSK/PSPD eksplisit, enrolment tutorial, pengguna & impor CSV, bahasa ID/EN
- **StudyProgram** dapat `code` (pssk/pspd, unik, huruf kecil) & `level` (sarjana/profesi); dua baris seed dibackfill di migrasi; halaman **Konfigurasi → Program Studi** (`/study_programs`, admin) untuk daftar/tambah/sunting. Dasar pembeda instrumen asesmen PSSK vs PSPD di Fase 25.
- **TutorialEnrollment** (`/tutorial_enrollments`) — padanan PSSK dari ClinicalRotation: mahasiswa ↔ blok/sistem (teks bebas) ↔ dosen tutor ↔ periode, unik per (mahasiswa, periode, blok), `active` bisa ditandai selesai. Admin CRUD; mahasiswa & tutor melihat miliknya (Pundit Scope). Tutee aktif kini ikut menjadi "mahasiswa bimbingan" tutor di Dashboard Analitik (`AnalyticsController#mentee_snapshots`).
- **Konfigurasi → Pengguna** (`/admin/users`, gerbang `has_role?("admin")`): daftar berpenyaring (nama/email, peran, prodi, paginasi), sunting nama/prodi/peran (peran aktif ikut disesuaikan bila dicabut; minimal satu peran), **reset kata sandi ke bawaan** `User::DEFAULT_PASSWORD`, dan **Impor CSV** lewat `UserCsvImporter` (header `email,nama,peran,prodi`; alias header ID/EN, pemisah koma/titik koma, BOM dibuang; peran gabungan `dosen+preseptor`; prodi kode atau nama; akun baru terkonfirmasi dengan kata sandi bawaan, akun lama hanya diperbarui; setiap baris gagal dilaporkan dengan nomor barisnya).
- **Bahasa ID/EN**: `users.locale_preference`, `around_action :switch_locale` (akun → cookie `locale` untuk halaman Devise pra-login → :id), tombol **EN/ID** di topbar (`PATCH /pengaturan/bahasa`, kembali ke halaman asal, pesan dalam bahasa baru), pilihan bahasa di Pengaturan Saya, `available_locales %i[id en]` + fallbacks dua arah. **Cakupan sengaja seperti jejak.pro: hanya cangkang** (sidebar, topbar, bilah bawah, Pengaturan Saya, Devise) — isi halaman konten tetap Indonesia; kunci di `config/locales/chrome.{id,en}.yml`.

21 test baru (205 total, hijau). Smoke HTTP: 8 akun × 32 halaman, nol 500. Screenshot: daftar Pengguna dalam EN (cangkang berbahasa Inggris, isi tetap Indonesia).

### ✅ Fase 24 — Pilar A: identitas pasien terenkripsi, Privacy Mode + Break Glass, QR persetujuan pasien, master Diagnosis/Keterampilan, target kasus FKTP/FKRTL
- **Identitas pasien** pada ClinicalCase (nama, No. RM, tanggal lahir, telepon, alamat) — kolom `encrypts` Active Record Encryption; kunci dari ENV `AR_ENCRYPTION_*` → credentials → (dev/test saja) diturunkan dari `secret_key_base`; production tanpa kunci menolak boot (`config/initializers/active_record_encryption.rb`). Usia persis & pekerjaan (`patient_age`, `patient_occupation`) **tidak** sensitif — keputusan pengelola 14 Sep 2026 — tampil di kepala halaman. Blok "Identitas Pasien" ditambahkan ke Langkah 1 wizard.
- **Contextual Privacy Mode** (`AppSetting`, bawaan MENYALA — gagal ke arah aman; ENV `PRIVACY_MODE` mengunci) menyamarkan identitas untuk semua pembaca termasuk pemilik (`AF***`, `RM-****56`, `••••`). **Break Glass**: tombol di kartu identitas → alasan ≥10 karakter → `BreakGlassAccess` 30 menit, IP tercatat, baris tak pernah dihapus; policy `break_glass?` = `show?`. **Konfigurasi → Data Governance** (`/admin/data_governance`): sakelar + 100 audit terakhir.
- **Persetujuan pasien via QR** (`PatientConsent`, token 32 karakter): pemilik kasus menerbitkan/menerbitkan ulang/mencabut dari halaman kasus; pasien membuka `/persetujuan/:token` (layout `public_consent`, tanpa login, tanpa isi kasus), mencentang 3 butir (pendidikan/foto/publikasi), menulis nama & relasi; jawaban tampil butir per butir di kasus; peringatan bila ada lampiran tapi foto tidak disetujui. *Beda dari jejak.pro*: QR hanya dari kasus yang sudah tersimpan (jejak.pro bisa sebelum simpan).
- **Master Diagnosis** (`DiagnosisDefinition`: nama, ICD-10, level SKDI, sistem) & **Master Keterampilan** (`SkillDefinition`) — CRUD admin + impor CSV (`MasterDataCsvImporter`, alias header ID/EN) + 42 diagnosis & 25 keterampilan seed. Diagnosis wizard jadi input ber-`datalist`; `ClinicalCase#sync_diagnosis_definition` menyalin `icd10_code`/`skdi_level` (lencana di halaman kasus). DOPS memakai master keterampilan, jatuh ke `COMMON_PROCEDURES` bila kosong.
- **Target Kasus Logbook** (`LogbookCaseTarget`: prodi × periode(opsional) × FKTP/FKRTL): CRUD admin; kartu "Pemenuhan Target Kasus" di Kasus Klinis menghitung kasus **terverifikasi** per fasilitas (`facility_type`: pelayanan_primer → FKTP, lainnya → FKRTL).
- **Pelajaran**: `helper_method :label` menimpa helper form `label` Rails → 500 di halaman form master data; tertangkap smoke HTTP, bukan test — sekarang ada test halaman new/edit. Dinamai ulang `resource_label`.

16 test baru (221 total, hijau). Smoke HTTP: 8 akun × 38 halaman, nol 500. Screenshot: halaman kasus tersamar dengan Break Glass + QR, lembar persetujuan pasien di lebar ponsel.

### ✅ Fase 25 — Pilar B: Assessment Events, impor CSV berpemetaan kolom, percobaan berulang, rubrik penguji, CBD/Long Case, jadwal WBA, Peta EPA, jurnal umpan balik
- **AssessmentEvent + AssessmentInstance menggantikan ExamImport/ExamScore** (Fase 12). Satu wadah untuk semua nilai, bertipe **14 instrumen** dalam empat keluarga: ujian tulis (CBT, nilai tutor, Tinjauan, TMEX, Progress Test), ujian praktik (OSCE), rubrik penguji (SOCA/MSP, Essay & Festival Gagasan, Community Project, Refleksi dinilai, EBCR), dan berbasis kasus (CBD, Long Case) — sesuai matriks PSSK/PSPD di `DAFTAR_FITUR_JEJAK.md` § Pilar B. Event dibatasi periode + prodi + blok/stase; `visible_to?` mencocokkan enrolment tutorial/rotasi aktif mahasiswa. **Migrasi menyalin data lama** (2 event, 3 nilai di dev); tabel `exam_imports`/`exam_scores` sengaja ditinggal untuk diverifikasi manual sebelum di-drop.
- **Percobaan berulang** (`allow_multiple_attempts`): unik per (event, mahasiswa, `attempt_number`); `AssessmentInstance.representative_for` memilih nilai tertinggi — jangan `find_by`.
- **Impor CSV 3 langkah berpemetaan kolom** (`AssessmentScoreImporter`): unggah → petakan (email, skor, nilai maks, nomor percobaan) dengan tebakan otomatis dari nama header → jalankan; pemisah `,`/`;`, desimal koma, BOM dibuang; email tak dikenal dilaporkan, tidak dibuat otomatis; event sekali-jalan menimpa percobaan 1.
- **Alur rubrik**: mahasiswa mendaftar (`/student/assessments`) → unggah dokumen + evaluasi diri → penguji menilai di **Lembar Penguji** (`/examiner_evaluations`; percobaan tanpa penguji boleh diambil) dengan nilai + umpan balik "pertahankan/tingkatkan" → notifikasi ke mahasiswa. Event boleh menunjuk Assessment Form Template (Fase 9) sebagai rubrik terstruktur.
- **CBD & Long Case dari kasus**: tombol Inisiasi di halaman kasus (status `submitted`/`verified` milik sendiri), kasus tertaut ke percobaan, penguji terisi dari verifier kasus atau preseptor rotasi aktif — meniru "inisiasi terintegrasi" jejak.pro.
- **Peta EPA & Tingkat Entrustment** (`/dashboard/entrustment`, `EntrustmentDecision`): level 1–5 per ranah kerangka kompetensi, **supersede** bukan timpa (riwayat tersimpan). Terisi otomatis saat verifikasi kasus bila verifier mencentang ranah EPA (peta 6 level kasus → 1–5), atau manual oleh pembimbing yang punya relasi (tutor enrolment, preseptor rotasi, pembimbing tugas akhir, verifier kasus).
- **Jadwal DOPS & Mini-CEX** (`EvaluationSchedule`) + kartu beranda "Jadwal mendatang" & "Asesmen menunggu"; **Evaluasi Akademik** (`/nilai-ujian`) kini per tipe asesmen dengan tren persentase; **Jurnal Umpan Balik Penguji** (`/student/feedback_journal`) menggabungkan umpan balik rubrik, CBD/Long Case, DOPS, dan Mini-CEX dalam satu linimasa.

23 test baru (228 total, hijau). Smoke HTTP: 8 akun × 45 halaman, nol 500. Screenshot: Asesmen Saya (mahasiswa) & Assessment Events (admin).

### ✅ Fase 26 — Pilar C: Assessment Matrix per Learning Unit & kurva persentil kohort
- **LearningUnit + AssessmentMapping** (`/admin/learning_units`, admin & kaprodi): blok/modul per prodi (opsional per periode, SKS, blueprint kompetensi) yang nilainya disusun dari beberapa Assessment Event dengan bobot. Halaman unit menampilkan total bobot (ditandai hijau saat 100%), penambahan/penghapusan komponen, dan **rekap nilai unit per mahasiswa**.
- **Perhitungan nilai unit**: rata-rata TERBOBOT persentase tiap komponen, tetapi **hanya dari komponen yang sudah dinilai** — bobot yang belum ada nilainya tidak masuk penyebut, dan angkanya dilabeli "dari X% bobot" supaya tidak terbaca sebagai nilai akhir. Percobaan wakil tiap event = nilai tertinggi (`AssessmentInstance.representative_for`).
- **Kurva persentil kohort** (`CohortPercentileCalculator`): posisi mahasiswa terhadap angkatannya, **per tipe asesmen** dan **dalam satu periode** — tidak pernah mencampur alat ukur atau antar-tahun (lihat catatan `assessment-type-mix-shifts-per-period`). Kohort **gabungan PSSK + PSPD** mengikuti jejak.pro. Pita P10–P90 + median + penanda posisi digambar dengan CSS (tanpa Plotly). **Penjaga privasi**: persentil hanya tampil bila kohort ≥ 3 mahasiswa, agar nilai perorangan tak bisa diterka.
- Keduanya tampil di **Analisis Capaian Pembelajaran** (`/capaian-belajar`) di bawah radar DOPS/Mini-CEX yang sudah ada, dan unit prodi lain tidak pernah tampil.

9 test baru (237 total, hijau). Smoke HTTP: 8 akun × 48 halaman, nol 500. Screenshot: Analisis Capaian Pembelajaran dengan Nilai Blok & Posisi terhadap Kohort.

**Paket Dasar (🟢) `DAFTAR_FITUR_JEJAK.md` v2.0 kini tertutup penuh di jejak-lite.** Yang tersisa dari tabel gap Fase 22: CDSS Fornas pada resep (sengaja ditunda — butuh katalog obat nasional yang tidak ada di tier ini).


## Fase 27 — Jalur pindah ke jejak.pro

### ✅ Fase 27 — Paket migrasi jejak-lite → jejak.pro
- `bin/rails migration:check` (hanya membaca) dan `bin/rails migration:export` (`MigrationExporter`) → paket berisi `manifest.json` (jumlah baris + SHA-256), `data/*.json` salinan lengkap semua tabel (tanpa kata sandi/token), `jejak_pro/*.csv` yang kolomnya adalah **kontrak** dengan importer jejak.pro, dan `lampiran/`.
- Identitas pasien tidak ikut kecuali `INCLUDE_PATIENT_IDENTITY=true` (dicatat di manifest; lampiran kasus/persetujuan dilewati bila tidak).
- Nilai dibawa sebagai persen + persen per ranah kompetensi (`kompetensi:<id>`), dengan hitungan yang sama seperti Peta Kompetensi (dimensi ujian + pertanyaan rubrik terpetakan).
- Sisi jejak.pro (repo PFKV2): `bin/rails jejak_lite:import` (`JejakLiteBundleImporter`) — uji coba bawaan, `COMMIT=1` semua-atau-tidak, idempoten; pengguna & rotasi lewat importer bawaan jejak.pro (`CsvUserImporter`, `ClinicalRotationImporter`); periode dipadankan lewat nama semester/tahun atau tumpang-tindih ≥ separuh (bukan tanggal mulai); bentrok NPM/NIDN dilaporkan dan ditautkan lewat `padanan_email.csv`; `bin/rails jejak_lite:referensi` menampilkan kode yang perlu diisi.
- Diuji ujung-ke-ujung: paket data demo → uji coba ke DB dev jejak.pro → galat terarah → isi kode periode & padanan email → uji coba bersih.
- Panduan lengkap: [`MIGRASI_KE_JEJAK_PRO.md`](MIGRASI_KE_JEJAK_PRO.md).

### ✅ Audit Paket Dasar 15 September 2026 — 4 celah PERILAKU ditutup (bukan cuma render error)

Diminta pengguna: "cek kembali semua fitur 🟢, pastikan tersedia & berfungsi, pelan-pelan, bertahap." Metode: cocokkan tiap baris `DAFTAR_FITUR_JEJAK.md` v2.0 dengan kode, crawl HTTP ~50 pola URL × 8 akun demo (nol error di tiap tahap), lalu baca controller/model/view untuk fitur yang secara render 200 OK tapi perilakunya belum lengkap. Fase 22–26 menutup *keberadaan halaman*; audit ini menemukan 4 tempat yang halamannya ada tapi **alurnya tidak lengkap**:

1. **Wizard Kasus Klinis cuma 4 langkah**, bukan 6 — Pemeriksaan Penunjang (lab/radiologi/lainnya) tidak ada kolom sama sekali; Terapi & Resep bercampur di langkah Diagnosis & Tatalaksana. Simpan Draf cuma muncul di langkah terakhir (wizard klien murni, jadi mahasiswa yang berhenti di langkah 1 tidak bisa simpan tanpa mengisi semua). Galat validasi ditumpuk jadi satu kalimat tanpa menunjuk langkah — pada form 6-langkah ini berarti mahasiswa harus menerka langkah mana yang salah.
2. **Verifikasi kasus cuma punya 2 aksi** (Verifikasi, Minta Revisi) — tidak ada Tolak (untuk kasus yang memang tidak layak, beda dari "perlu revisi"), tidak ada Batalkan Verifikasi (verifier salah pilih kasus, tidak ada jalan mundur — level EPA yang sudah ditulis pun ikut tersangkut), tidak ada komentar diskusi di luar siklus status.
3. **Mini-CEX/DOPS cuma bisa dibuat dosen dari nol** — `DAFTAR_FITUR_JEJAK.md` §Pilar B eksplisit: "diinisiasi dari kasus, dinilai penguji" (pola sama dengan CBD/Long Case yang SUDAH ada). Sebelum audit, mahasiswa tidak ada jalan meminta Mini-CEX/DOPS dari kasus yang sudah ditulisnya.
4. **Logbook Kegiatan (ActivityLog) tanpa mekanisme verifikasi APA PUN** — tidak ada kolom status, tidak ada policy, controller-nya scoped mutlak ke `current_user.activity_logs` (tidak ada cara pengajar membuka log siswa lain). `DAFTAR_FITUR_JEJAK.md` M02 eksplisit menyebut "penanda terverifikasi" sebagai 🟢.

**Ditutup**: migrasi kolom (`laboratory_results`/`radiology_results`/`other_investigations`, `dops_evaluations.clinical_case_id`/`mini_cex_evaluations.clinical_case_id`, `activity_logs.verified_at`/`verified_by_id`); `ClinicalCase#reject!`/`#cancel_verification!`/`#add_verification_comment!`; status `requested` di `DimensionScorable` (dimensi wajib tidak berlaku sebelum penilai mulai mengisi); `ActivityLogPolicy` baru + scope "Perlu Diverifikasi" + nav "Validasi Kegiatan" + penanda warna Kalender. Juga ditambah pengingat pencatatan kasus di Beranda (mahasiswa berotasi, 2 hari tanpa kasus baru — pola sama `CASE_LOGGING_GAP_DAYS` jejak.pro).

28 test baru (336 total, hijau). Smoke HTTP ulang setiap tahap perubahan: 8 akun × ~50 pola URL, nol error di semua tahap. Verifikasi visual: screenshot headless Chrome tiap alur baru (wizard 6 langkah, panel Tolak/Batalkan Verifikasi, kartu WBA dari kasus, halaman Validasi Kegiatan, Kalender berpenanda).

**Belum diperiksa mendalam di audit ini** (halaman render 200 OK & test lulus, tapi belum ditelusuri sedalam 4 poin di atas): impor CSV Assessment Event ujung-ke-ujung dengan berkas nyata, Assessment Form Builder → rubrik SOCA/MSP end-to-end, kurva persentil kohort dengan data >3 mahasiswa sungguhan, Assessment Matrix dengan bobot campuran. **Gap arsitektur yang TIDAK ditutup** (di luar cakupan audit, butuh keputusan produk): "Pilihan Academic Club pada asesmen" (🟢 M05) — jejak-lite sengaja tanpa modul komunitas sejak awal (lihat "Yang Sengaja Disederhanakan/Ditunda"), jadi field `academic_club_id` semacam ini tidak punya tempat berlabuh tanpa membangun ulang sebagian modul komunitas.

### ✅ Relabel Prodi Mahasiswa (17 September 2026)

Diminta pengguna: "tambahkan fitur relabel prodi mahasiswa seperti yang ada di jejak.pro". Catatan tingkat: `DAFTAR_FITUR_JEJAK.md` v2.0 mencatat "Relabel status mahasiswa, transfer kohort" sebagai 🟡, bukan 🟢; fitur ini ditambahkan atas permintaan eksplisit.

- `/admin/student_relabel` (`Admin::StudentRelabelsController` + `StudentProgramRelabeler`), padanan `/management/student_relabel` jejak.pro: unggah CSV `email,npm,angkatan` → pratinjau per baris dengan catatan → terapkan dalam satu transaksi. Kolom `email` boleh diisi NPM lama; `npm` = NPM baru; `angkatan` kosong = angkatan default form (atau tidak diubah).
- Aksi **Pindah** (admin: semua mahasiswa; kaprodi: hanya mahasiswa prodinya) dan **Label ke prodi saya** (khusus kaprodi; tujuan dikunci server-side ke `users.study_program_id` kaprodi). Mode "Tandai Lulus" jejak.pro **tidak dibawa**: jejak-lite tidak punya status/persona alumni.
- Baris dilewati, tidak menggagalkan batch: tidak ditemukan, NPM lama cocok >1 akun, bukan peran Mahasiswa, akun muncul dua kali, angkatan tak terbaca, di luar prodi kaprodi, NPM baru dobel/dipakai akun lain, tidak ada perubahan, atau data akun tidak lolos validasi model (dicek saat pratinjau).
- Menu: Konfigurasi (admin) dan Coaching Center (peran aktif kaprodi yang bukan admin). Jejak audit hanya di log aplikasi (`[student_relabel]`) — jejak-lite tidak punya tabel audit umum seperti `AccessAuditLog`.
- 22 test baru (390 total, hijau); smoke HTTP 8 akun lolos; alur pratinjau → terapkan dicoba lewat HTTP ke DB dev (akun demo dikembalikan).

### ✅ Taksonomi Logbook Kegiatan & Taksonomi Istilah (17 September 2026)

Diminta pengguna (dengan tangkapan layar menu Konfigurasi): "`/activity_logs/new` belum sesuai dengan jejak.pro, terutama pada kategori dan belum ada sub kategori; di akun admin belum ada menu untuk edit kategori dan sub kategori kalender, dan belum ada edit label menu/istilah". Di jejak.pro, `/activity_logs` tampil sebagai menu "Kalender", jadi "kategori kalender" = taksonomi Logbook Kegiatan.

- **Taksonomi 3 tingkat meniru jejak.pro**: `AcademicActivityDomain` → `AcademicActivitySubdomain` ("Subdomain / Kategori") → `AcademicActivityTemplate` ("Bentuk Kegiatan", opsional). Nama tabel & kolom sama dengan jejak.pro, plus `is_clinical` khusus jejak-lite untuk menurunkan `activity_logs.category` (masih dibaca Portfolio, feed iCal, kode pasien). Isi bawaan (`AcademicActivityTaxonomySeeder`) disalin dari struktur **DB jejak.pro**, bukan dari seed-nya: "Tutorial" dkk. adalah subdomain langsung di bawah Belajar Mengajar. Seeder hanya mengisi basis data yang belum punya domain sama sekali (db:seed jalan tiap deploy Render; domain yang dihapus admin tidak hidup lagi). Instalasi berjalan mendapatkannya dari migrasi `20260917010005`.
- **Form `/activity_logs/new` disusun ulang seperti jejak.pro**: Domain* → Subdomain/Kategori → Bentuk Kegiatan (isian bertingkat, `activity_taxonomy_controller.js`, disembunyikan bila tak punya pilihan), Topik*, Lokasi, Waktu Mulai*/Selesai (`started_at`/`ended_at`, `activity_date` kini turunan), Metode Pelaksanaan*, Rotasi Klinik/Wahana, Semester (otomatis bila tepat satu periode mencakup tanggalnya), Catatan, Refleksi, Kompetensi, Dokumen & Bukti (`evidence_url`/`document_url` + unggahan). Isian wajib hanya ditegakkan dari form (`require_form_fields`), bukan pada fixture/demo/kegiatan lama. Pilihan nonaktif tidak bisa dipilih baru, tapi yang sudah tersimpan tetap sah. Kegiatan lama tanpa domain tetap tampil sebagai Klinis/Non-Klinis + teks `activity_type`; migrasi hanya menautkan yang namanya sama persis (tidak menebak). Filter indeks kini per domain (parameter `domain_id`: `domain:` adalah opsi host di URL helper Rails dan dibuang diam-diam).
- **Konfigurasi → Domain Kegiatan Akademik** (`/admin/academic_activity_domains`, label sama dengan jejak.pro): satu halaman pohon; tambah/sunting/geser urutan/aktif-nonaktif/hapus di tiga tingkat, jumlah pemakaian per simpul, hapus ditolak bila sudah dipakai (`restrict_with_error`, dideklarasikan sebelum `dependent: :destroy`).
- **Konfigurasi → Taksonomi Istilah** (`/admin/terminology`): mengganti label semua kunci `nav.*` (menu sidebar, judul grup, bilah bawah ponsel) dan `terms.*` (istilah halaman Logbook Kegiatan, `config/locales/terms.id.yml`). Daftar kunci dibaca dari berkas locale (`Terminology`), jadi menu baru otomatis bisa diganti. Tabel `terminology_overrides` (satu baris per kunci; kosong/sama dengan bawaan = dihapus). Helper `term(...)` menggantikan `t("nav.*")` di sidebar & bilah bawah. Label menu hanya berlaku di Bahasa Indonesia, sedangkan istilah halaman berlaku di kedua bahasa.
- Perbaikan yang ikut ditemukan: menyunting kegiatan dulu **menghapus semua lampiran** bila tidak ada unggahan baru (hidden field kosong dari `file_field multiple` → `DeleteMany` di Rails 8), dan unggahan baru menimpa yang lama. Kini lampiran ditambahkan lewat `attach`. Mengosongkan semua centang kompetensi dulu tidak menghapus tautan (tanpa hidden field kosong).
- **Paket migrasi format 1.1**: `logbook_kegiatan.csv` + `domain subdomain bentuk_kegiatan waktu_mulai waktu_selesai link_bukti link_dokumen` di ujung (aditif); `data/*.json` ikut tiga tabel taksonomi & `terminology_overrides`. Sisi jejak.pro (`JejakLiteBundleImporter`, repo PFKV2) mencocokkan nama ke taksonomi jejak.pro. Nama tak dikenal hanya diperingatkan. Dry-run paket asli ke DB dev jejak.pro: Prestasi Kemahasiswaan → Kompetisi → Juara-1 dikenali.
- Verifikasi: 368 test hijau (30 baru), rubocop & brakeman bersih, smoke HTTP 6 akun × 55 URL lolos, headless Chrome (isian bertingkat, simpan, penyaring & ganti label, lebar 400px tanpa scroll horizontal). **Jebakan uji browser**: dialog "kata sandi bocor" Chrome (password123) menelan ketikan selenium hanya pada sebagian akun. Matikan `PasswordLeakDetection` di opsi Chrome. **Jebakan dev**: `public/assets/.manifest.json` basi membuat controller Stimulus baru tidak dimuat (hapus manifest, jangan precompile ulang).

## Model Data (ringkas, akan detail per fase saat digarap)

| Tabel | Fase | Status |
|---|---|---|
| `users`, `roles`, `user_roles` | 1 | ✅ |
| `active_storage_*` | 1 | ✅ |
| `notifications`, `device_push_tokens` | 3 | ✅ |
| `activity_logs` | 4 | ✅ |
| `clinical_cases` | 5 | ✅ |
| `study_programs`, `academic_periods`, `clinical_rotations` | 6 | ✅ |
| `reflection_entries` | 7 | ✅ |
| `dops_evaluations`, `mini_cex_evaluations` | 8 | ✅ |
| `assessment_form_templates`, `assessment_form_fields`, `assessment_form_submissions`, `assessment_form_answers` | 9 | ✅ |
| `final_projects`, `final_project_milestones`, `examiner_scores` | 11 | ✅ |
| `assessment_blueprints`, `competency_frameworks`, `competency_items` | 13 | ✅ |
| `exam_imports`, `exam_scores` (cbt/osce/progress_test) | 12+14 | ✅ |
| _(tanpa tabel baru — agregasi lintas model yang sudah ada)_ | 15 | ✅ |
| _(kolom baru pada dops_evaluations/mini_cex_evaluations)_ | 17 | ✅ |
| `case_verification_comments`, `activity_log_competency_tags` (+ kolom baru activity_logs/clinical_cases) | 18 | ✅ |
| _(tanpa tabel baru — agregasi lintas model yang sudah ada)_ | 19 | ✅ |
| `assessment_blueprint_mappings`, `competency_milestones` | 20 | ✅ |
| _(kolom baru pada clinical_cases: anamnesis dkk + vital_signs)_ | 21 | ✅ |

## Menjalankan & Menguji

```bash
bin/rails db:setup   # create + migrate + seed peran dasar
bin/dev              # server + Tailwind watcher
bin/rails test       # 309 test lulus per Fase 27
```

## Yang Sengaja Disederhanakan/Ditunda

- Community Feed (media sosial internal) — diputuskan tidak diperlukan sama sekali.
- Household/family graph continuity of care → iterasi berikutnya.
- Pencarian global saat ini hanya mencakup `User` — diperluas ke Logbook/Kasus Klinis begitu ada (Fase 4-5).
- "Analisis Capaian Pembelajaran" (Fase 13) dihitung langsung dari DOPS/Mini-CEX/ExamScore saat halaman dibuka, bukan tabel `academic_assessment_results` tersimpan — lebih sederhana & tak ada risiko data basi, tapi berarti tidak ada riwayat snapshot historis (kartu capaian versi tanggal X tidak bisa "dibekukan").
- DOPS/Mini-CEX tetap form baku (bukan dibangun lewat Form Builder) — form builder khusus untuk evaluasi yang bentuknya bisa berubah-ubah (tutor/blok/tambahan).
- `ActivityCaseDatum` 100+ kolom + PII terenkripsi + lab/radiologi/detail bedah/follow-up SOAP + token QR tamu (arsitektur kasus klinis JEJAK asli) — `ClinicalCase` jejak-lite tetap SATU model yang diperkaya (Fase 18), bukan dipecah jadi arsitektur `ActivityLog`+`ActivityCaseDatum`; butuh infrastruktur enkripsi yang bertentangan dengan single-tenant/ringan.
- `CompetencyDomain`/`CompetencyGrowthTarget`/`CohortCompetencyBenchmark`/`CompetencyGrowthAlert`/`StudentCompetencyTrajectory` (mesin kurva pertumbuhan lintas-kohort JEJAK asli) — butuh data multi-tahun untuk bermakna dan bertentangan dengan pelajaran yang sudah didokumentasikan sendiri (tren capaian antar tahun selalu palsu karena jenis asesmen berganti).
- Plotly.js — Chart.js yang sudah dimuat (via Chartkick) cukup untuk semua kebutuhan radar/line jejak-lite; tidak perlu 2 library charting.
- Voice input + "Enhance ✨" AI pada narrative comment DOPS/Mini-CEX — butuh integrasi API AI, di luar cakupan (Gemfile sengaja tanpa gem AI sejak awal).
- `tom-select` untuk dropdown evaluator/mahasiswa — disebut di rencana awal tapi belum pernah dipasang; ditunda, jumlah user jejak-lite masih kecil sehingga `<select>` polos cukup.
- Dual verification queue architecture (namespace `Supervisor::...` terpisah) — aksi member `verify`/`request_revision` yang sudah ada di `ClinicalCasesController` sudah cukup untuk skala jejak-lite.
- Linkage skor-per-domain kompetensi (skor DOPS/Mini-CEX terpetakan presisi ke satu `CompetencyItem`) — tidak dibangun karena butuh mesin mapping dimensi↔kompetensi seperti `AssessmentDimensionMapping` JEJAK asli (dengan whitelist dimensi per kategori asesmen). Badge target milestone di Capaian Belajar (Fase 20) pakai proksi rata-rata keseluruhan, dilabeli jelas sebagai itu — bukan klaim presisi per-ranah yang datanya belum ada.
