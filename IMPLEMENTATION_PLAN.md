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

## Menjalankan & Menguji

```bash
bin/rails db:setup   # create + migrate + seed peran dasar
bin/dev              # server + Tailwind watcher
bin/rails test       # 154 test lulus per Fase 17
```

## Yang Sengaja Disederhanakan/Ditunda

- Community Feed (media sosial internal) — diputuskan tidak diperlukan sama sekali.
- Household/family graph continuity of care → iterasi berikutnya.
- Pencarian global saat ini hanya mencakup `User` — diperluas ke Logbook/Kasus Klinis begitu ada (Fase 4-5).
- "Analisis Capaian Pembelajaran" (Fase 13) dihitung langsung dari DOPS/Mini-CEX/ExamScore saat halaman dibuka, bukan tabel `academic_assessment_results` tersimpan — lebih sederhana & tak ada risiko data basi, tapi berarti tidak ada riwayat snapshot historis (kartu capaian versi tanggal X tidak bisa "dibekukan").
- DOPS/Mini-CEX tetap form baku (bukan dibangun lewat Form Builder) — form builder khusus untuk evaluasi yang bentuknya bisa berubah-ubah (tutor/blok/tambahan).
