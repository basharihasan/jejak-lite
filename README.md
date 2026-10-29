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

Cara utama: **Docker atau Podman** — tarik image dari GHCR. **Tidak perlu** install Ruby/Rails/Node di host.

**Prasyarat:** Docker Compose **atau** Podman Compose.

1. Buat `.env` (tanpa Ruby):

   ```bash
   # Linux / macOS
   chmod +x script/setup-env.sh
   ./script/setup-env.sh --host 127.0.0.1:3000 --port 3000
   ```

   ```bat
   REM Windows
   script\setup-env.cmd -HostAddress 127.0.0.1:3000 -Port 3000
   ```

   Skrip mengisi `POSTGRES_PASSWORD`, `SECRET_KEY_BASE`, dan tiga kunci `AR_ENCRYPTION_*`. Sesuaikan `APP_HOST` jika akses dari mesin lain (IP LAN).

2. Tarik image & jalankan:

   ```bash
   docker compose pull && docker compose up -d
   # Podman: podman compose pull && podman compose up -d
   ```

   Image default: `ghcr.io/basharihasan/jejak-lite:latest`. Kalau `pull` gagal `unauthorized`, paket GHCR masih privat — `docker login ghcr.io` (PAT `read:packages`) atau minta owner set Packages → Public. Detail: [`NAS_DEPLOY.md`](NAS_DEPLOY.md).

3. Seed data rujukan + akun demo (opsional):

   ```bash
   docker compose exec web bin/rails db:seed
   docker compose exec web bin/rails demo:seed
   ```

4. Buka <http://127.0.0.1:3000> (atau `http://<APP_HOST>`).

Hentikan: `docker compose down` (jalankan dari folder repo yang sama tempat `.env` / `up` dijalankan).

QNAP/Synology, HTTPS (Caddy), R2: [`NAS_DEPLOY.md`](NAS_DEPLOY.md).

### Data demo (akun contoh)

`demo:seed` membuat akun contoh (password semua: `password123` — **hanya demo**):

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

Idempoten; terpisah dari `db/seeds.rb` (data rujukan aplikasi).

### Alternatif: Ruby native (pengembang)

Untuk ubah kode tanpa container: Ruby (lihat `.ruby-version`), PostgreSQL lokal, Node tidak perlu.

1. `.env` dengan `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_HOST` / `POSTGRES_PORT`
2. `bundle install` → `bin/rails db:setup` → `bin/dev` → <http://localhost:3000>

`bin/dev` = Rails + Tailwind watcher. Port lain: `PORT=3060 bin/dev`. Windows: `ruby bin/rails ...` bila shell menolak skrip tanpa ekstensi.

Di **development/test**, kunci enkripsi pasien diturunkan dari `secret_key_base`. Di **production** (termasuk Compose) wajib `AR_ENCRYPTION_*` di `.env` (disiapkan `setup-env`). Login Google / Web Push opsional lewat env (`GOOGLE_*`, `VAPID_*`).

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
- **Unggahan** (foto profil, lampiran kegiatan & kasus, dokumen asesmen): tanpa konfigurasi tambahan tersimpan di disk lokal container, yang **terhapus setiap deploy ulang** di Render free. Isi `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, dan `R2_BUCKET` (Cloudflare R2, kuota gratis 10 GB) — produksi otomatis memakai layanan `cloudflare` di `config/storage.yml`. Bucket boleh privat dan tidak perlu aturan CORS. Berkas yang diunggah sebelum R2 aktif tidak ikut pindah.
- Keempat "role" database (primary/cache/queue/cable) sengaja berbagi satu database fisik (lihat komentar di `config/database.yml`) supaya cukup satu instance Postgres gratis — aman karena masing-masing solid_* punya nama tabel unik, tapi berarti backup/restore tidak bisa dipisah per peran.

## Yang Sengaja Tidak Dibawa dari JEJAK

Lihat bagian "Yang Sengaja Disederhanakan/Ditunda" di [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) — antara lain Community Feed, portal pasien token publik, hierarki Faculty/University, dan integrasi Glide untuk impor nilai (diganti CSV generik).

## Lisensi

Hak cipta © 2026 Muhammad Hasan Bashari.

Kode sumber jejak-lite dilisensikan di bawah **GNU Affero General Public License v3.0** (AGPL-3.0) — teks lengkapnya di [`LICENSE`](LICENSE). Anda bebas memakai, mempelajari, mengubah, dan menyebarkan ulang aplikasi ini, termasuk meng-hosting-nya untuk institusi Anda sendiri, dengan syarat versi yang Anda ubah juga dirilis di bawah AGPL-3.0. Karena jejak-lite adalah aplikasi web, syarat itu berlaku pula bila versi yang diubah hanya dijalankan sebagai layanan daring: pengguna layanan tersebut harus dapat memperoleh kode sumbernya (pasal 13 AGPL-3.0).

Logo Universitas Padjadjaran, AIPKI, dan Kemdiktisaintek (di `public/branding/` serta `app/views/shared/_aipki_logo.html.erb` dan `_diktisaintek_logo.html.erb`) adalah milik lembaga masing-masing dan **tidak termasuk** dalam lisensi ini.
