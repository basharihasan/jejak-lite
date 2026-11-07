# Menjalankan JEJAK Essential di NAS / VPS (Docker atau Podman)

Self-host lewat Compose: image **sudah dibangun CI** →
`ghcr.io/basharihasan/jejak-lite:latest`. Host **tidak perlu** Ruby/Rails.
Cocok untuk QNAP, Synology, VPS Linux, atau Windows + Docker Desktop.

Nama `jejak-lite` / `jejak_lite` pada image, database, dan volume sengaja tidak
diganti: instalasi yang sudah berjalan menyimpan datanya di bawah nama itu.

## Prasyarat

- Docker Engine + Compose plugin, **atau** Podman + `podman-compose`
- (Sekali) generator `.env`: `openssl` di Linux/macOS, atau PowerShell di Windows

## 1. Siapkan `.env` (tanpa Ruby)

```bash
# Linux / macOS (Debian, Ubuntu, Fedora, RHEL, Arch, …)
chmod +x script/setup-env.sh
./script/setup-env.sh --host 192.168.1.50:3000 --port 3000
```

```bat
REM Windows (cmd)
script\setup-env.cmd -HostAddress 192.168.1.50:3000 -Port 3000
```

```powershell
# Windows PowerShell
.\script\setup-env.ps1 -HostAddress 192.168.1.50:3000 -Port 3000
```

Atau salin `.env.example` → `.env` dan isi manual (`openssl rand -hex …`).

Simpan `.env`. Ganti kunci enkripsi nanti = data pasien lama tidak terbaca.

## 2. Tarik image & jalankan (tanpa build)

```bash
docker compose pull
docker compose up -d
```

Podman: ganti dengan `podman-compose` / `podman compose`.

Data rujukan terisi otomatis saat basis data pertama kali dibuat. Buka `http://<APP_HOST>`, lalu buat akun admin pertama (langkah berikutnya).

Kalau `pull` → **unauthorized**: paket GHCR masih privat. Owner repo harus
**Packages → jejak-lite → Change visibility → Public** (atau workflow
`docker-publish` yang sudah mencoba set public setelah push). Sementara:
`docker login ghcr.io` + PAT `read:packages`.

## 3. Akun admin pertama

Halaman Daftar hanya menghasilkan akun Mahasiswa, dan instalasi baru mulai dengan pendaftaran mandiri tertutup. Pilih salah satu cara:

**Lewat `.env`, tanpa terminal.** Isi sebelum `docker compose up -d`:

```bash
ADMIN_EMAIL=admin@kampus.ac.id
ADMIN_PASSWORD=kata-sandi-awal
ADMIN_NAME=Nama Admin
```

Akun dibuat sekali saat kontainer berjalan, selama belum ada admin sama sekali. Kata sandinya wajib diganti saat masuk pertama, dan tidak pernah direset ulang saat kontainer dimulai lagi. Kosongkan `ADMIN_PASSWORD` setelah berhasil masuk.

**Lewat terminal:**

```bash
docker compose exec -e ADMIN_EMAIL=admin@kampus.ac.id -e ADMIN_PASSWORD='kata-sandi-kuat' -e ADMIN_NAME='Nama Admin' web bin/rails users:create_admin
```

Perintah ini juga mereset kata sandi bila akunnya sudah ada.

Setelah masuk, ikuti daftar **Langkah Penyiapan** di Beranda dan **Panduan Penyiapan** di menu Panduan Penggunaan.

> **Jangan jalankan `demo:seed` di server sungguhan.** Perintah itu membuat akun contoh, termasuk Admin, yang bebas dari kewajiban ganti kata sandi. Di mode produksi ia ditolak kecuali diminta dengan `ALLOW_DEMO_DATA=1` dan `DEMO_PASSWORD`, khusus untuk instance percobaan.

## 4. Port

`HOST_PORT` di host → **3000 di dalam** kontainer. Contoh benar:
`"6969:3000"`. Salah: `"6969:6969"`.

## QNAP Container Station

1. Create with `docker-compose.yml`
2. Environment Variables = isi `.env` (`SECRET_KEY_BASE`, tiga
   `AR_ENCRYPTION_*`, `POSTGRES_PASSWORD`, `APP_HOST`, `HOST_PORT`, …
   — **bukan** `RAILS_MASTER_KEY`)
3. Untuk admin pertama, isi juga `ADMIN_EMAIL` dan `ADMIN_PASSWORD` di Environment Variables, lalu kosongkan `ADMIN_PASSWORD` setelah berhasil masuk. Alternatifnya: setelah Running → Exec `web`, lalu jalankan `users:create_admin` seperti di atas.

## Update versi

Setelah CI publish image baru ke `:latest`:

```bash
docker compose pull
docker compose up -d
```

Volume DB/unggahan tetap (jangan `down -v` kecuali sengaja wipe).

## HTTPS publik (opsional)

[`docker-compose.https.yml`](docker-compose.https.yml) + Caddy. Set
`CADDY_DOMAIN`; `ASSUME_SSL`/`FORCE_SSL` true di belakang TLS.
