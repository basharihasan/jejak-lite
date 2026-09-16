# Menjalankan JEJAK Essential di NAS (QNAP)

Dokumen ini untuk deployment **self-hosted** lewat Docker — cocok untuk QNAP
(Container Station), Synology (Container Manager), TrueNAS SCALE, Unraid,
atau server Linux mana pun yang punya Docker. Image dibangun otomatis oleh
GitHub Actions (`.github/workflows/docker-publish.yml`) setiap push ke
`master`, jadi NAS tinggal **menarik** image jadi — tidak perlu build sendiri.

## Sekali di awal (di komputer Anda, bukan di NAS)

1. **Buat Personal Access Token GitHub** untuk NAS menarik image privat:
   - github.com → foto profil → **Settings** → **Developer settings** →
     **Personal access tokens** → **Tokens (classic)** → **Generate new token**
   - Scope: centang **`read:packages`** saja
   - Simpan tokennya (cuma tampil sekali)

2. **Buat kunci enkripsi KHUSUS deployment NAS ini** (jangan pakai ulang kunci
   dari deployment trial online sebelumnya):
   ```
   bin/rails db:encryption:init
   ```
   Catat 3 nilainya.

3. **Salin isi `config/master.key`** (satu baris).

## Di QNAP — Container Station

### A. Login ke GitHub Container Registry

Container Station → **Preferences** (ikon gerigi) → **Registry** → **Add** →
- Registry: `ghcr.io`
- Username: akun GitHub Anda (`basharihasan`)
- Password: Personal Access Token dari langkah 1 (bukan password akun)

### B. Buat aplikasi dari docker-compose.yml

1. Container Station → **Applications** → **Create** → tab
   **"Create with docker-compose.yml"** (nama tab bisa "YAML" di versi lain)
2. Nama aplikasi: `jejak-lite`
3. Tempel isi [`docker-compose.yml`](docker-compose.yml) dari repo ini
4. Di bagian **Environment Variables** (Container Station biasanya
   menyediakan kolom ini terpisah dari YAML, karena tidak selalu membaca
   `.env`), isi semua yang ada di [`.env.example`](.env.example):

   | Variabel | Isi dengan |
   |---|---|
   | `POSTGRES_PASSWORD` | kata sandi acak pilihan Anda |
   | `RAILS_MASTER_KEY` | isi `config/master.key` |
   | `AR_ENCRYPTION_PRIMARY_KEY` | dari `db:encryption:init` |
   | `AR_ENCRYPTION_DETERMINISTIC_KEY` | dari `db:encryption:init` |
   | `AR_ENCRYPTION_KEY_DERIVATION_SALT` | dari `db:encryption:init` |
   | `APP_HOST` | IP NAS Anda + port, mis. `192.168.1.50:3000`, atau domain QNAP DDNS (`namananda.myqnapcloud.com:3000`) |
   | `HOST_PORT` | `3000` (atau port lain kalau 3000 sudah dipakai) |

5. **Create** — Container Station menarik `postgres:16-alpine` dan
   `ghcr.io/basharihasan/jejak-lite:latest`, lalu menjalankan keduanya.

### C. Isi akun demo (sekali saja)

Setelah kontainer `web` berstatus **Running**:

Container Station → aplikasi `jejak-lite` → kontainer `web` → **Terminal**
(atau **Exec**), jalankan:
```
bin/rails demo:seed
```
Ini membuat akun admin/dosen/preseptor/mahasiswa contoh (password
`password123`) untuk langsung dicoba.

### D. Akses aplikasi

Buka `http://<IP-NAS-Anda>:3000` (atau port yang Anda pilih) dari perangkat
mana pun di jaringan yang sama.

## Memperbarui ke versi kode terbaru

Tiap kali ada perubahan yang di-push ke `master`, image baru otomatis
terbangun (~5-8 menit, bisa dipantau di tab **Actions** repo GitHub). Di
Container Station: buka aplikasi `jejak-lite` → **Update** (atau hapus &
buat ulang kontainer `web` saja, `db` dan datanya tidak ikut terhapus karena
tersimpan di volume terpisah) — Container Station menarik ulang tag
`:latest` yang baru.

## Membuka akses dari luar jaringan rumah/kantor (opsional)

Bawaan di atas hanya bisa diakses dari jaringan lokal yang sama dengan NAS.
Untuk diakses dari luar (mis. dicoba tim yang tidak sekantor):
- **QNAP myQNAPcloud** (DDNS bawaan QNAP) + port forwarding di router ke
  port yang dipetakan di langkah B, ATAU
- Reverse proxy dengan HTTPS (QNAP App Center → **QuMagie**/`Container
  Station` bawaan reverse proxy, atau pasang Caddy/Nginx Proxy Manager
  sebagai kontainer terpisah) — supaya lalu lintas terenkripsi TLS, bukan
  HTTP polos, sebelum ini dianggap layak diakses dari internet.

Membuka NAS langsung ke internet tanpa HTTPS/firewall yang benar berisiko —
kalau butuh bantuan menyiapkan reverse proxy + TLS, beri tahu, jangan
langsung port-forward tanpa itu.
