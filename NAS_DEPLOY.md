# Menjalankan JEJAK Lite di NAS / VPS (Docker atau Podman)

Self-host lewat Compose: image **sudah dibangun CI** →
`ghcr.io/basharihasan/jejak-lite:latest`. Host **tidak perlu** Ruby/Rails.
Cocok untuk QNAP, Synology, VPS Linux, atau Windows + Docker Desktop.

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
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails demo:seed   # opsional
```

Podman: ganti dengan `podman-compose` / `podman compose`.

Buka `http://<APP_HOST>`. Demo: lihat README (`password123`).

Kalau `pull` → **unauthorized**: paket GHCR masih privat. Owner repo harus
**Packages → jejak-lite → Change visibility → Public** (atau workflow
`docker-publish` yang sudah mencoba set public setelah push). Sementara:
`docker login ghcr.io` + PAT `read:packages`.

## 3. Port

`HOST_PORT` di host → **3000 di dalam** kontainer. Contoh benar:
`"6969:3000"`. Salah: `"6969:6969"`.

## QNAP Container Station

1. Create with `docker-compose.yml`
2. Environment Variables = isi `.env` (`SECRET_KEY_BASE`, tiga
   `AR_ENCRYPTION_*`, `POSTGRES_PASSWORD`, `APP_HOST`, `HOST_PORT`, …
   — **bukan** `RAILS_MASTER_KEY`)
3. Setelah Running → Exec `web` → `bin/rails demo:seed`

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
