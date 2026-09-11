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

### ⬜ Fase 6 — Jadwal Rotasi & Periode Akademik
`study_programs` (2 baris tetap, ditautkan ke `users.study_program_id`), `AcademicPeriod`, `ClinicalRotation` — termasuk **tampilan jadwal** untuk mahasiswa (kalender rotasi per periode, wahana, preseptor pembimbing). Fondasi bagi DOPS/Mini-CEX (Fase 8) dan Dashboard Analitik (Fase 15).

### ⬜ Fase 7 — Modul Refleksi (Jurnal Digital)
Entri jurnal reflektif tersendiri (bukan field di ActivityLog) — mendukung pembelajaran reflektif berkelanjutan, bisa ditautkan ke kegiatan/kasus tertentu atau berdiri sendiri.

### ⬜ Fase 8 — DOPS & Mini-CEX
Form skor tetap (rubrik baku, bukan builder), pakai `ClinicalRotation`+`AcademicPeriod` dari Fase 6.

### ⬜ Fase 9 — Assessment Form Builder
Infrastruktur formulir dinamis (jenis field, skala skor, dimensi penilaian) — dipakai Fase 10 (Formulir Evaluasi) dan berpotensi Fase 12 (Progress Test).

### ⬜ Fase 10 — Formulir Evaluasi
Tutor Evaluation (evaluasi dosen tutor oleh mahasiswa), Evaluasi Blok, asesmen tambahan lain — didefinisikan lewat Form Builder (Fase 9).

### ⬜ Fase 11 — Tugas Akhir
Alur skripsi/proyek akhir: milestone, sesi ujian, skor penguji — versi ringan dari `ScholarlyProject` JEJAK.

### ⬜ Fase 12 — Progress Test
Tes berkala lintas periode; skor lewat skema `exam_imports`/`exam_scores` (kolom `kind: "progress_test"`) — dibangun bareng Fase 14 (Import CBT/OSCE) untuk satu skema tiga jenis ujian.

### ⬜ Fase 13 — Kurikulum Dasar
Blueprinting (`AssessmentBlueprint`), Peta Kompetensi, Analisis Capaian Pembelajaran.

### ⬜ Fase 14 — Import CBT/OSCE (+ Progress Test)
Importer CSV generik → `exam_imports`/`exam_scores` terpadu (kolom `kind`: cbt/osce/progress_test).

### ⬜ Fase 15 — Dashboard Analitik (Dosen, Preseptor, Kaprodi)
Butuh peran `preseptor`+`kaprodi` (ditambah di fase ini). Agregasi lintas mahasiswa: progres logbook, hasil DOPS/Mini-CEX, kehadiran rotasi, hasil evaluasi — per dosen (mahasiswa bimbingannya), per preseptor (mahasiswa di wahananya), per Kaprodi (satu program studi, via `study_programs` dari Fase 6).

### ⬜ Fase 16 — Deploy & Poles
Pilih target deploy, seed data demo, smoke test alur emas end-to-end, README final.

## Model Data (ringkas, akan detail per fase saat digarap)

| Tabel | Fase | Status |
|---|---|---|
| `users`, `roles`, `user_roles` | 1 | ✅ |
| `active_storage_*` | 1 | ✅ |
| `notifications`, `device_push_tokens` | 3 | ✅ |
| `activity_logs` | 4 | ✅ |
| `clinical_cases` | 5 | ✅ |
| `study_programs`, `academic_periods`, `clinical_rotations` | 6 | ⬜ |
| `reflection_entries` | 7 | ⬜ |
| `dops_evaluations`, `mini_cex_evaluations` | 8 | ⬜ |
| `assessment_form_templates`, `assessment_form_fields` | 9 | ⬜ |
| `evaluation_submissions` (tutor/blok/tambahan) | 10 | ⬜ |
| `final_projects`, `final_project_milestones`, `examiner_scores` | 11 | ⬜ |
| `assessment_blueprints`, `competency_frameworks`, `competency_items`, `academic_assessment_results` | 13 | ⬜ |
| `exam_imports`, `exam_scores` (cbt/osce/progress_test) | 12, 14 | ⬜ |

## Menjalankan & Menguji

```bash
bin/rails db:setup   # create + migrate + seed peran dasar
bin/dev              # server + Tailwind watcher
bin/rails test       # 63 test lulus per Fase 5
```

## Yang Sengaja Disederhanakan/Ditunda

- Community Feed (media sosial internal) — diputuskan tidak diperlukan sama sekali.
- Household/family graph continuity of care → iterasi berikutnya.
- Pencarian global saat ini hanya mencakup `User` — diperluas ke Logbook/Kasus Klinis begitu ada (Fase 4-5).
- DOPS/Mini-CEX tetap form baku (bukan dibangun lewat Form Builder) — form builder khusus untuk evaluasi yang bentuknya bisa berubah-ubah (tutor/blok/tambahan).
