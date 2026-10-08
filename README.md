# Jejak Lite

Versi ringan dan berdiri sendiri dari fitur "Dasar" JEJAK (lihat `DAFTAR_FITUR_JEJAK.md` di repo utama `PFKV2`) — logbook kegiatan, kasus klinis, rotasi, asesmen (DOPS/Mini-CEX/Progress Test/CBT/OSCE), kurikulum (blueprint & peta kompetensi), dan dashboard analitik untuk dosen/preseptor/Kaprodi. **Bukan fork** — dibangun ulang dari nol sebagai aplikasi Rails 8 yang benar-benar terpisah, single-tenant (tanpa Organization/RLS/IAM enterprise milik JEJAK), supaya bisa di-hosting sendiri lepas dari JEJAK utama.

Rencana lengkap, keputusan arsitektur, dan status tiap fase (0–16, semua ✅) ada di [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).

## Fitur

Seluruh baris **tingkat Dasar (🟢)** pada `DAFTAR_FITUR_JEJAK.md` di repo utama `PFKV2` — tidak lebih:

- **Akun & Peran** — multi-peran per akun (mahasiswa/dosen/preseptor/kaprodi/admin) + Ganti Peran; login email/password atau Google; kelola pengguna & impor CSV; bahasa antarmuka ID/EN; tema terang/gelap/ikuti sistem.
- **Pencatatan Kasus** — wizard Kasus Klinis 4 langkah, identitas pasien terenkripsi dengan **Privacy Mode** + **Break Glass** beraudit, QR persetujuan pasien (halaman publik tanpa login), master Diagnosis/ICD-10 & Keterampilan, target kasus FKTP/FKRTL, logbook kegiatan + kalender/iCal, verifikasi preseptor.
- **Asesmen** — Assessment Events (CBT, nilai tutor, Tinjauan, TMEX, Progress Test, OSCE, SOCA/MSP, esai & festival gagasan, community project, refleksi dinilai, EBCR, CBD, Long Case) dengan impor CSV berpemetaan kolom, unggah berkas CSV format ekspor Glide (*CBT Exam Results* & *Penilaian OSCE* 8 dimensi klinis — tanpa API Glide) beserta Kelola Ujian CBT, riwayat & rollback impor, percobaan berulang, alur rubrik mahasiswa→penguji, DOPS & Mini-CEX + jadwalnya, jurnal umpan balik penguji.
- **Pemetaan Capaian** — Peta Kompetensi per periode, Peta EPA & Tingkat Entrustment (1–5, ber-supersede), Assessment Matrix per Learning Unit, kurva persentil kohort (gabungan PSSK+PSPD), portofolio longitudinal.
- **Kurikulum & Rotasi** — periode akademik, program studi (pssk/pspd), rotasi klinik, enrolment tutorial, blueprint & kerangka kompetensi.
- **Dashboard Analitik & Notifikasi** — `/analitik` per peran; notifikasi in-app + Web Push (VAPID).

Rencana lengkap & status tiap fase (0–26, semua ✅) ada di [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).

## Menjalankan secara lokal


**Prasyarat:** Ruby (sesuai `.ruby-version`), PostgreSQL yang berjalan, dan Node tidak diperlukan (Tailwind & importmap tanpa bundler JS).

1. Buat `.env` berisi kredensial Postgres lokal:

   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=...
   POSTGRES_HOST=127.0.0.1
   POSTGRES_PORT=5432
   ```

2. `bundle install`
3. `bin/rails db:setup` (create + migrate + seed data rujukan: peran, program studi, templat formulir, kerangka kompetensi & blueprint, master diagnosis & keterampilan, contoh Learning Unit)
4. `bin/dev` → buka <http://localhost:3000>

`bin/dev` menjalankan Rails server + Tailwind watcher sekaligus (lewat `Procfile.dev`). Ganti port dengan `PORT=3060 bin/dev`.

Kalau tidak ingin memakai foreman, jalankan dua terminal:

```bash
ruby bin/rails server            # terminal 1
ruby bin/rails tailwindcss:watch # terminal 2 — hanya perlu saat mengubah tampilan
```

> **Windows:** panggil lewat `ruby bin/rails ...` (bukan `bin/rails ...`) bila shell Anda menolak menjalankan skrip tanpa ekstensi. Bila port 3000 sudah dipakai proses lain, hentikan dulu (`netstat -ano | findstr :3000`, lalu `taskkill /PID <pid> /F`) atau pakai port lain.

Login Google (opsional) aktif otomatis kalau `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` diisi di `.env`. Web Push (opsional) aktif kalau `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY`/`VAPID_SUBJECT` diisi.

### Kunci enkripsi data pasien

Identitas pasien pada Kasus Klinis (nama, No. RM, tanggal lahir, telepon, alamat) disimpan terenkripsi (Active Record Encryption). Di **development/test** kuncinya diturunkan otomatis dari `secret_key_base` — tidak perlu setup. Di **production** wajib diisi, kalau tidak aplikasi sengaja menolak boot:

```env
AR_ENCRYPTION_PRIMARY_KEY=...
AR_ENCRYPTION_DETERMINISTIC_KEY=...
AR_ENCRYPTION_KEY_DERIVATION_SALT=...
```

Hasilkan ketiganya dengan `bin/rails db:encryption:init`. Opsional: `PRIVACY_MODE=true|false` mengunci sakelar Contextual Privacy Mode dari server (bawaannya menyala, diatur admin lewat **Konfigurasi → Data Governance**).

### Data demo (opsional, untuk mencoba semua fitur)

```bash
bin/rails demo:seed
```

Membuat 8 akun contoh (password sama semua: `password123`, sengaja lemah — **hanya untuk demo**, jangan pernah dipakai untuk akun sungguhan):

| Email | Peran | Kegunaan |
|---|---|---|
| `admin.demo@jejaklite.test` | Admin | Akses penuh — kelola periode, impor nilai, kurikulum |
| `dosen.demo@jejaklite.test` | Dosen | Membimbing tugas akhir, menilai DOPS/Mini-CEX |
| `preseptor.demo@jejaklite.test` | Preseptor | Membimbing mahasiswa di rotasi/wahana |
| `kaprodi.demo@jejaklite.test` | Kaprodi | Dashboard Analitik satu program studi |
| `multirole.demo@jejaklite.test` | Mahasiswa + Dosen | Contoh satu akun berperan ganda (fitur Ganti Peran) |
| `mahasiswa1.demo@jejaklite.test` | Mahasiswa | Punya logbook, kasus klinis, DOPS/Mini-CEX, tugas akhir, nilai ujian |
| `mahasiswa2.demo@jejaklite.test` | Mahasiswa | Kasus klinis & nilai ujian (untuk melihat agregasi lintas mahasiswa) |
| `demo@jejaklite.test` | Mahasiswa + Dosen | Akun serba-guna untuk mencoba cepat |

Task ini idempoten (aman dijalankan berkali-kali) dan terpisah dari `db/seeds.rb` karena isinya akun contoh berpassword publik, bukan data rujukan aplikasi.

## Pindah ke jejak.pro

Data jejak-lite bisa dipindahkan utuh ke jejak.pro tanpa ketik ulang:

```bash
bin/rails migration:check     # periksa kesiapan data (hanya membaca)
bin/rails migration:export    # buat paket migrasi di tmp/migrasi-jejak-pro-<waktu>/
```

Paket lalu diimpor di jejak.pro dengan `bin/rails jejak_lite:import` (uji coba dulu, `COMMIT=1` untuk menyimpan). Langkah lengkap, pemetaan data, dan penanganan data pasien ada di [MIGRASI_KE_JEJAK_PRO.md](MIGRASI_KE_JEJAK_PRO.md).

## Test

```bash
bin/rails test   # 237 test, semua hijau per Fase 26
```

Selain test suite, tiap fase diverifikasi dengan **smoke test HTTP sungguhan**: login sebagai tiap akun demo lalu membuka seluruh halaman sidebar, memastikan nol 500. Cara cepat melakukannya sendiri: jalankan server, lalu buka halaman-halaman itu sebagai `admin.demo@jejaklite.test` dan `mahasiswa1.demo@jejaklite.test`.

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
