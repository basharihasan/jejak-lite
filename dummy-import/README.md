# Berkas dummy impor — JEJAK Essential

Semua berkas di folder ini berisi **data rekaan** untuk mencoba fitur impor. Tidak ada data pasien atau mahasiswa sungguhan. Setiap berkas sudah pernah diimpor ke https://jejak-lite.onrender.com.

| Berkas | Diimpor di | Isi |
|---|---|---|
| `01_master_diagnosis.csv` | Konfigurasi → Master Diagnosis → Impor CSV | 5 diagnosis (ICD-10, level SKDI, sistem) |
| `02_master_keterampilan.csv` | Konfigurasi → Master Keterampilan → Impor CSV | 4 keterampilan klinis |
| `03_master_obat.csv` | Konfigurasi → Master Obat → Impor CSV | 4 obat (kekuatan, sediaan, kategori, dosis lazim) |
| `04_pengguna.csv` | Konfigurasi → Pengguna → Impor CSV | 6 mahasiswa, 1 dosen, 1 preseptor (`dummy.*@jejaklite.test`) |
| `05_relabel_prodi.csv` | Konfigurasi → Relabel Prodi Mahasiswa (mode Pindah, tujuan Profesi Dokter) | Memindahkan dummy.mhs05 & 06 beserta NPM baru |
| `05b_relabel_klaim_kaprodi.csv` | Relabel Prodi Mahasiswa sebagai **kaprodi** (mode Label ke prodi saya) | Mengklaim dummy.mhs06 ke prodi binaan |
| `06_nilai_dummy_cbt_blok_respirasi.csv` | Assessment Events → *Dummy CBT Blok Respirasi* → Impor CSV | Dibuat dari **Unduh templat CSV** event itu, lalu diisi nilai 3 dimensi |
| `07_cbt_exam_results_glide.csv` | Konfigurasi → Impor CSV CBT & OSCE → CBT Exam Results | 6 mahasiswa, 10 dimensi berkategori (format ekspor Glide) |
| `08_penilaian_osce_glide.csv` | Konfigurasi → Impor CSV CBT & OSCE → OSCE | 24 station (6 mahasiswa × 4 station), 8 dimensi klinis 0–3 |
| `lampiran/` | Logbook Kegiatan, Kasus Klinis, Profil, Asesmen rubrik | PNG & PDF kecil untuk uji unggah lampiran |

## Catatan

- Akun hasil impor `04_pengguna.csv` memakai **kata sandi bawaan** aplikasi. Situs ini terbuka di internet, jadi ganti kata sandinya atau hapus akunnya bila situs dipakai sungguhan.
- Mengimpor ulang berkas master data hanya **memperbarui** baris yang namanya sama. Impor CBT/OSCE ulang dilewati sebagai "sudah diimpor".
- Impor CBT/OSCE yang keliru bisa dibatalkan lewat **Riwayat Impor → Rollback**.
