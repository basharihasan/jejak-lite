# Jejak Lite

Versi ringan dan berdiri sendiri dari fitur "Dasar" JEJAK (lihat `DAFTAR_FITUR_JEJAK.md` di repo utama `PFKV2`) — logbook kegiatan, kasus klinis, rotasi, asesmen (DOPS/Mini-CEX/Progress Test/CBT/OSCE), kurikulum (blueprint & peta kompetensi), dan dashboard analitik untuk dosen/preseptor/Kaprodi. **Bukan fork** — dibangun ulang dari nol sebagai aplikasi Rails 8 yang benar-benar terpisah, single-tenant (tanpa Organization/RLS/IAM enterprise milik JEJAK), supaya bisa di-hosting sendiri lepas dari JEJAK utama.

Rencana lengkap, keputusan arsitektur, dan status tiap fase (0–16, semua ✅) ada di [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).

## Fitur

- **Akun & Peran** — multi-peran per akun (mahasiswa/dosen/preseptor/kaprodi/admin) dengan fitur ganti peran aktif; login email/password atau Google.
- **Logbook & Kasus Klinis** — pencatatan kegiatan klinis/non-klinis, kasus klinis dengan alur verifikasi dosen/preseptor, kalender + feed iCal.
- **Rotasi & Periode Akademik** — jadwal rotasi per mahasiswa, dikelola admin.
- **Asesmen** — DOPS & Mini-CEX (skala 1–9, dimensi wajib profesionalisme/komunikasi), Assessment Form Builder (dipakai untuk Evaluasi Tutor/Blok/lainnya), Tugas Akhir + milestone + skor penguji, Progress Test/CBT/OSCE lewat impor CSV.
- **Kurikulum** — Blueprint Asesmen (peta bobot kompetensi), Peta Kompetensi (pohon ranah/sub-kompetensi), halaman "Analisis Capaian Pembelajaran" pribadi per periode.
- **Dashboard Analitik** — satu halaman `/analitik` yang menampilkan bagian berbeda sesuai peran: mahasiswa bimbingan (dosen), mahasiswa di wahana (preseptor), seluruh mahasiswa satu program studi (Kaprodi).
- **Notifikasi** — in-app + Web Push (VAPID).

## Menjalankan secara lokal

1. Salin `.env.example` (kalau ada) atau buat `.env` berisi kredensial Postgres lokal:

   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=...
   POSTGRES_HOST=127.0.0.1
   POSTGRES_PORT=5432
   ```

2. `bundle install`
3. `bin/rails db:setup` (create + migrate + seed data rujukan: peran, program studi, templat formulir baku, contoh peta kompetensi & blueprint)
4. `bin/dev` (menjalankan Rails server + Tailwind watcher lewat Procfile.dev)

Login Google (opsional) aktif otomatis kalau `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` diisi di `.env`. Web Push (opsional) aktif kalau `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY`/`VAPID_SUBJECT` diisi.

### Data demo (opsional, untuk mencoba semua fitur)

```bash
bin/rails demo:seed
```

Membuat 7 akun contoh (password sama semua: `password123`, sengaja lemah — **hanya untuk demo**, jangan pernah dipakai untuk akun sungguhan):

| Email | Peran | Kegunaan |
|---|---|---|
| `admin.demo@jejaklite.test` | Admin | Akses penuh — kelola periode, impor nilai, kurikulum |
| `dosen.demo@jejaklite.test` | Dosen | Membimbing tugas akhir, menilai DOPS/Mini-CEX |
| `preseptor.demo@jejaklite.test` | Preseptor | Membimbing mahasiswa di rotasi/wahana |
| `kaprodi.demo@jejaklite.test` | Kaprodi | Dashboard Analitik satu program studi |
| `multirole.demo@jejaklite.test` | Mahasiswa + Dosen | Contoh satu akun berperan ganda (fitur Ganti Peran) |
| `mahasiswa1.demo@jejaklite.test` | Mahasiswa | Punya logbook, kasus klinis, DOPS/Mini-CEX, tugas akhir, nilai ujian |
| `mahasiswa2.demo@jejaklite.test` | Mahasiswa | Kasus klinis & nilai ujian (untuk melihat agregasi lintas mahasiswa) |

Task ini idempoten (aman dijalankan berkali-kali) dan terpisah dari `db/seeds.rb` karena isinya akun contoh berpassword publik, bukan data rujukan aplikasi.

## Test

```bash
bin/rails test
```

## Deploy (Render, opsional)

`render.yaml` menyediakan blueprint satu web service + satu Postgres gratis (tanpa Docker — Render mendeteksi Ruby dari `Gemfile`). Langkah:

1. Push repo ke GitHub, lalu di Render pilih **New → Blueprint** dan arahkan ke repo ini.
2. Isi `RAILS_MASTER_KEY` (isi `config/master.key`) di dashboard Render — nilainya sengaja tidak ada di `render.yaml`.
3. Render menjalankan `bin/render-build.sh` (bundle install, precompile aset, migrate semua database peran solid_queue/solid_cache/solid_cable, lalu `db:seed`).
4. Jalankan `bin/rails demo:seed` sekali lewat Render Shell kalau ingin instance demo publik yang bisa langsung dicoba.

Keterbatasan yang perlu diketahui sebelum deploy sungguhan (bukan sekadar demo):
- `config.active_storage.service = :local` (lihat `config/storage.yml`) — berkas (avatar, bukti kegiatan) tersimpan di disk lokal container, **hilang setiap deploy ulang** di PaaS dengan filesystem sementara seperti Render free tier. Untuk produksi sungguhan, aktifkan `amazon:`/S3 di `config/storage.yml` (gem `aws-sdk-s3` sudah ada di Gemfile) dan ganti `config.active_storage.service`.
- Keempat "role" database (primary/cache/queue/cable) sengaja berbagi satu database fisik (lihat komentar di `config/database.yml`) supaya cukup satu instance Postgres gratis — aman karena masing-masing solid_* punya nama tabel unik, tapi berarti backup/restore tidak bisa dipisah per peran.

## Yang Sengaja Tidak Dibawa dari JEJAK

Lihat bagian "Yang Sengaja Disederhanakan/Ditunda" di [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) — antara lain Community Feed, portal pasien token publik, hierarki Faculty/University, dan integrasi Glide untuk impor nilai (diganti CSV generik).
