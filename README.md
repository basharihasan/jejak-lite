# Jejak Lite

Versi ringan dan berdiri sendiri dari fitur "Dasar" JEJAK (lihat `DAFTAR_FITUR_JEJAK.md` di repo utama) — logbook kegiatan, komunitas, dan asesmen dasar (DOPS/Mini-CEX). Aplikasi ini **tidak** memakai konsep multi-tenant/Organization/RLS milik JEJAK; setiap instalasi berdiri sendiri (single-tenant).

## Menjalankan secara lokal

1. Salin `.env.example` (kalau ada) atau buat `.env` berisi kredensial Postgres lokal:
   ```
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=...
   POSTGRES_HOST=127.0.0.1
   POSTGRES_PORT=5432
   ```
2. `bundle install`
3. `bin/rails db:setup` (create + migrate + seed peran dasar: mahasiswa/dosen/admin)
4. `bin/dev` (menjalankan Rails server + Tailwind watcher lewat Procfile.dev)

Login Google (opsional) aktif otomatis kalau `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` diisi di `.env`.

## Status Pengembangan

Dibangun bertahap mengikuti roadmap fase di rencana implementasi. Status saat ini:

- [x] Fase 0 — Skeleton (Rails 8, Postgres, Tailwind, Solid Queue/Cache/Cable)
- [x] Fase 1 — Auth & Peran (Devise + Google OAuth opsional, multi-peran per akun, ganti peran aktif, profil + avatar)
- [ ] Fase 2 — Dashboard & Navigasi lanjutan, Pencarian global, Panduan Pengguna
- [ ] Fase 3 — Notifikasi (in-app + Web Push)
- [ ] Fase 4 — Logbook & Aktivitas
- [ ] Fase 5 — Community Feed
- [ ] Fase 6 — Kasus Klinis dasar
- [ ] Fase 7 — Rotasi minimal + DOPS/Mini-CEX
- [ ] Fase 8 — Kurikulum dasar (Blueprinting, Peta Kompetensi, Analisis Capaian)
- [ ] Fase 9 — Import CBT/OSCE (CSV generik)
- [ ] Fase 10 — Deploy & Poles

## Test

```
bin/rails test
```
