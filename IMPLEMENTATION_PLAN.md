# Rencana Implementasi Jejak Lite

Dokumen ini adalah pelacak progres hidup — diperbarui setiap fase selesai. Untuk detail riset awal (kenapa dibangun ulang, bukan fork), lihat riwayat percakapan atau tanyakan Claude Code; ringkasannya ada di bagian **Konteks** di bawah.

## Konteks

Jejak Lite adalah aplikasi Rails 8 **terpisah total** dari JEJAK utama (PFKV2), berisi hanya subset fitur "Dasar" yang didaftarkan di `DAFTAR_FITUR_JEJAK.md` (repo PFKV2). Tujuannya kemungkinan dijual/di-hosting sendiri, lepas dari JEJAK.

Dibangun ulang dari nol (bukan fork-lalu-hapus) karena riset menemukan `Organization`/RLS/IAM JEJAK ditenun wajib (FK `NOT NULL`) ke model-model inti (`User`, `ActivityLog`, `DopsEvaluation`, `MiniCexEvaluation`) — 121 dari 124 model JEJAK punya `belongs_to :organization` wajib. Fork akan menyeret seluruh mesin multi-tenant yang tidak relevan untuk aplikasi single-tenant.

## Keputusan Arsitektur Kunci

| Keputusan | Alasan |
|---|---|
| Single-tenant, tanpa Organization/RLS/SaaS | Jejak Lite = satu instalasi = satu institusi |
| Multi-peran per akun tetap ada, tapi lewat `roles`+`user_roles` sederhana | Bukan FunctionalRole/UserPersona/Capability JEJAK yang enterprise-grade |
| DOPS/Mini-CEX bawa `ClinicalRotation`+`AcademicPeriod` versi MINIMAL | JEJAK mewajibkan FK itu di kedua model evaluasi — tak bisa dilepas total |
| Import CBT/OSCE via CSV generik | Bukan integrasi Glide (API pihak ketiga milik institusi asal JEJAK) |
| `study_programs` diisi tepat 2 baris: **Sarjana Kedokteran** & **Profesi Dokter** | Permintaan eksplisit — tidak perlu hierarki multi-fakultas |
| `json` gem dikunci `~> 2.7` | json 3.x memutus `ActiveSupport::JSON.decode`/dekripsi cookie sesi di Rails 8.1.3.1 — ditemukan lewat 500 di SEMUA request saat testing Fase 1 |
| Kamal/Thruster/Dockerfile dilepas dari skeleton | Target deploy diputuskan di Fase 10, bukan dipaksa ikut default `rails new` |

## Tumpukan Teknologi

Rails 8.1.3, PostgreSQL, Propshaft, Importmap + Turbo + Stimulus, Tailwind v4, Devise + `omniauth-google-oauth2` (opsional via ENV), Pundit, Solid Queue/Cache/Cable, Kaminari, ActiveStorage (`ruby-vips`), `rqrcode`, `kramdown`, `web-push`, `discard`, `active_storage_validations`, `rack-attack`/`rack-timeout`/`strong_migrations`, `csv`.

## Model Data

| Tabel | Status | Keterangan |
|---|---|---|
| `users` | ✅ Ada | Devise (`database_authenticatable, registerable, recoverable, rememberable, validatable, trackable, confirmable, omniauthable`) |
| `roles`, `user_roles` | ✅ Ada | Seed: mahasiswa, dosen, admin |
| `active_storage_*` | ✅ Ada | Untuk avatar profil |
| `notifications`, `device_push_tokens` | ⬜ Belum | Fase 3 |
| `activity_logs`, `activity_case_data` | ⬜ Belum | Fase 4 & 6 |
| `patient_consents`/`case_reviews` (token publik) | ⬜ Belum | Fase 6 |
| `community_posts`, `post_comments`, reaksi & bookmark | ⬜ Belum | Fase 5 |
| `study_programs` | ⬜ Belum | Fase 5 — 2 baris tetap (lihat Keputusan Arsitektur) |
| `academic_periods`, `clinical_rotations` (minimal) | ⬜ Belum | Fase 7 |
| `dops_evaluations`, `mini_cex_evaluations` | ⬜ Belum | Fase 7 |
| `assessment_blueprints` | ⬜ Belum | Fase 8 |
| `competency_frameworks`, `competency_items` | ⬜ Belum | Fase 8 |
| `academic_assessment_results` | ⬜ Belum | Fase 8 |
| `exam_imports`, `exam_scores` (skema terpadu CBT+OSCE) | ⬜ Belum | Fase 9 |

## Roadmap & Status

### ✅ Fase 0 — Skeleton (selesai, commit `48439c4`)
Rails 8 + Postgres + Tailwind + Solid Queue/Cache/Cable. Gemfile disaring ke ~30 gem esensial.

### ✅ Fase 1 — Auth & Peran (selesai, commit `48439c4`)
- Devise lengkap (daftar/masuk/lupa sandi/konfirmasi email), Google OAuth opsional
- `Role`/`UserRole` + `User#switch_active_role!` (fitur Ganti Peran)
- Profil (nama + avatar)
- Layout + topbar (dropdown ganti peran, profil, keluar)
- 9 test, semua lulus

### ✅ Fase 2 — Dashboard & Navigasi (selesai, commit `479cdf6`)
- Dashboard: kartu "Langkah Berikutnya" berbeda per `active_role.code`
- Pencarian pengguna (nama/email) — baru mencakup `User`, akan diperluas begitu ada tipe konten lain
- Panduan Pengguna (markdown → HTML via Kramdown)
- Halaman `/brand` publik
- 18 test total, semua lulus

### ⬜ Fase 3 — Notifikasi
`Notification` (in-app: tandai dibaca/arsipkan) + `DevicePushToken` (Web Push) + job pengiriman.

### ⬜ Fase 4 — Logbook & Aktivitas
`ActivityLog` (refleksi, skor, evidence/attachment), kalender + feed iCal, QR pasien untuk pencatatan cepat.

### ⬜ Fase 5 — Community Feed
`CommunityPost`/`PostComment`/reaksi/bookmark. Kanal Pengumuman Prodi (tag `study_programs` — 2 baris tetap).

### ⬜ Fase 6 — Kasus Klinis Dasar
Kasus klinis + verifikasi supervisor, portal pasien token publik (consent/feedback/survey tanpa login). Household/family graph DITUNDA ke iterasi berikutnya.

### ⬜ Fase 7 — Rotasi Minimal + DOPS/Mini-CEX
`AcademicPeriod`+`ClinicalRotation` versi minimal (data pendukung, bukan modul penjadwalan), form & skor DOPS/Mini-CEX.

### ⬜ Fase 8 — Kurikulum Dasar
Blueprinting (`AssessmentBlueprint`, berdiri sendiri tanpa FK), Peta Kompetensi (pohon sederhana), Analisis Capaian Pembelajaran (skor per user+periode).

### ⬜ Fase 9 — Import CBT/OSCE
Importer CSV generik → skema `exam_imports`/`exam_scores` terpadu (kolom `kind`: cbt/osce) — bukan dua pipeline terpisah seperti JEJAK.

### ⬜ Fase 10 — Deploy & Poles
Pilih target deploy, seed data demo, smoke test alur emas end-to-end, README final.

## Menjalankan & Menguji

```
bin/rails db:setup   # create + migrate + seed peran dasar
bin/dev               # server + Tailwind watcher
bin/rails test        # 18 test, semua lulus per Fase 2
```

## Yang Sengaja Disederhanakan/Ditunda

- Household/family graph continuity of care → iterasi berikutnya.
- Kanal Pengumuman Prodi pakai tag `study_programs` ringan (2 baris tetap), bukan hierarki Faculty/University.
- CBT & OSCE satu skema terpadu (`exam_imports`/`exam_scores` + kolom `kind`), bukan dua pipeline seperti JEJAK.
- Pencarian global saat ini hanya mencakup `User` — akan diperluas ke Logbook/Community Feed begitu fitur itu ada (Fase 4-5).
