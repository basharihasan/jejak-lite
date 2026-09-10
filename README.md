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

Lihat [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) untuk rencana lengkap, keputusan arsitektur, dan status progres per fase (diperbarui tiap fase selesai).

## Test

```
bin/rails test
```
