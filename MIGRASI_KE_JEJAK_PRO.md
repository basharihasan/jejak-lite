# Migrasi jejak-lite → jejak.pro

Panduan untuk institusi yang ingin naik dari jejak-lite (paket Dasar, di-host sendiri) ke jejak.pro. Migrasi memakai **satu paket ekspor** dari jejak-lite dan **satu perintah impor** di jejak.pro. Keduanya diuji otomatis terhadap kontrak kolom yang sama.

## Ringkasan

| Tahap | Di mana | Perintah |
| --- | --- | --- |
| 1. Periksa kesiapan data | jejak-lite | `bin/rails migration:check` |
| 2. Buat paket | jejak-lite | `bin/rails migration:export` |
| 3. Lihat kode yang tersedia | jejak.pro | `bin/rails jejak_lite:referensi ORG=…` |
| 4. Uji coba impor | jejak.pro | `bin/rails jejak_lite:import DIR=… ORG=… TEMPLATE_ID=…` |
| 5. Simpan | jejak.pro | perintah yang sama + `COMMIT=1` |

Uji coba tidak menyimpan apa pun. Penyimpanan bersifat semua-atau-tidak: selama masih ada galat, tidak ada yang tersimpan, jadi tidak pernah ada migrasi setengah jadi. Impor juga boleh diulang karena data yang sudah masuk dikenali dan tidak digandakan.

## 1. Periksa kesiapan (jejak-lite)

```bash
bin/rails migration:check
```

Perintah ini hanya membaca. Yang dilaporkan: pengguna tanpa email, mahasiswa tanpa NPM/prodi, rotasi tanpa periode, serta dimensi ujian dan pertanyaan rubrik yang belum dipetakan ke ranah kompetensi. Tidak ada yang wajib, tetapi setiap temuan yang dibereskan di sini membuat impor lebih lengkap.

## 2. Buat paket (jejak-lite)

```bash
bin/rails migration:export                                  # ke tmp/migrasi-jejak-pro-<waktu>/
bin/rails migration:export DIR=/backup/paket                # folder pilihan
bin/rails migration:export INCLUDE_PATIENT_IDENTITY=true    # ikut identitas pasien
```

Isi paket:

| Berkas | Isi |
| --- | --- |
| `manifest.json` | versi format, jumlah baris dan checksum SHA-256 setiap berkas |
| `PANDUAN_MIGRASI.md` | langkah singkat untuk operator jejak.pro |
| `data/*.json` | salinan lengkap semua tabel, termasuk kolom yang tidak punya padanan (jaring pengaman) |
| `jejak_pro/pengguna.csv` | berbentuk `CsvUserImporter` jejak.pro |
| `jejak_pro/padanan_email.csv` | kosong; diisi bila seseorang sudah punya akun jejak.pro dengan email lain |
| `jejak_pro/periode.csv` | nama dan tanggal periode, plus kolom kosong **Kode Periode jejak.pro** |
| `jejak_pro/rotasi_klinik.csv` | berbentuk `ClinicalRotationImporter` jejak.pro |
| `jejak_pro/kasus_klinis.csv` | kasus klinis, termasuk resep dan tanda vital |
| `jejak_pro/logbook_kegiatan.csv` | logbook kegiatan dan refleksinya; sejak format 1.1 juga nama domain, subdomain, dan bentuk kegiatan, waktu mulai/selesai, serta tautan bukti/dokumen |
| `jejak_pro/kompetensi.csv` | ranah kompetensi, plus kolom kosong **Kode Kompetensi jejak.pro** |
| `jejak_pro/daftar_event_asesmen.csv` | event asesmen, plus kolom kosong **ID Event jejak.pro** / **ID Template jejak.pro** |
| `jejak_pro/nilai/*.csv` | nilai per event: nilai asli, persen, mentah per dimensi, persen per ranah kompetensi |
| `jejak_pro/pemetaan_kompetensi.csv` | acuan pemetaan dimensi/rubrik → ranah (untuk dibaca manusia) |
| `jejak_pro/lampiran.csv` + `lampiran/` | berkas unggahan |

### Versi format

Paket berformat **1.1** sejak 17 September 2026: `logbook_kegiatan.csv` mendapat tujuh kolom baru di ujung (`domain`, `subdomain`, `bentuk_kegiatan`, `waktu_mulai`, `waktu_selesai`, `link_bukti`, `link_dokumen`). Perubahannya hanya menambah kolom, jadi importer jejak.pro versi lama tetap bisa membacanya, hanya tanpa kolom baru itu. Importer versi baru mencocokkan domain, subdomain, dan bentuk kegiatan ke taksonomi jejak.pro **berdasarkan nama**. Nama yang tidak ditemukan dilaporkan sebagai peringatan, dan kegiatannya tetap masuk tanpa tingkat itu. Domain yang dibuat admin jejak-lite sendiri perlu dibuat dulu dengan nama yang sama di jejak.pro (Domain Kegiatan Akademik) sebelum `COMMIT=1`.

### Data pasien

Secara bawaan, identitas pasien (nama, No. RM, tanggal lahir, telepon, alamat) **tidak ikut**: kolomnya dikosongkan dan lampiran kasus/persetujuan pasien dilewati. `INCLUDE_PATIENT_IDENTITY=true` memindahkannya sebagai teks biasa, dan manifest mencatat pilihan itu. Perlakukan paket tersebut sebagai rekam medis. No. RM tidak pernah tersimpan di jejak.pro karena jejak.pro hanya menyimpan hash-nya.

Kata sandi dan token tidak pernah ikut dalam kondisi apa pun.

## 3–5. Impor (jejak.pro)

Persiapan sekali di jejak.pro:

1. Organisasi tujuan sudah ada (catat *slug*-nya).
2. Periode akademik yang dicakup data sudah dibuat.
3. Program studi dan master Blok Klinis sudah ada. Kolom "Program Studi" dicocokkan ke nama atau kode prodi.
4. Kerangka kompetensi sudah ada.
5. Pilih satu template alur (WorkflowTemplate) untuk event asesmen yang dibuat dari paket.

Semua kode dan ID yang dibutuhkan bisa dilihat dengan:

```bash
bin/rails jejak_lite:referensi ORG=fk-contoh
```

```text
PERIODE AKADEMIK — isi 'Kode Periode jejak.pro' di jejak_pro/periode.csv
  ganjil_2025_2026           Ganjil 2025-2026               2025-08-01 s.d. 2026-01-31
KOMPETENSI — isi 'Kode Kompetensi jejak.pro' di jejak_pro/kompetensi.csv
  area1              Mawas Diri dan Pengembangan Diri                             SNPPDI 2019
TEMPLATE ALUR — TEMPLATE_ID=<id> atau 'ID Template jejak.pro' di jejak_pro/daftar_event_asesmen.csv
  5      SOCA
```

Lalu:

```bash
# uji coba
bin/rails jejak_lite:import DIR=/lokasi/paket ORG=fk-contoh TEMPLATE_ID=5

# simpan
bin/rails jejak_lite:import DIR=/lokasi/paket ORG=fk-contoh TEMPLATE_ID=5 COMMIT=1
```

### Contoh nyata

Laporan uji coba paket data demo jejak-lite ke jejak.pro (dipotong):

```text
Periode akademik       di paket 1 · dipadankan 0 · lewat kode 0 · belum dipadankan 1
  ! Periode '2026/2027 Ganjil' (2026-08-01 s.d. 2027-01-31) belum punya padanan (terdekat 'Genap 2025/2026'
    Genap_2025_2026, hanya tumpang-tindih 14 dari 184 hari) — buat periodenya di jejak.pro atau isi
    'Kode Periode jejak.pro' di periode.csv.

Pengguna               di paket 11 · baru 10 · diperbarui 0 · ditautkan/dilewati 0 · GALAT 1
  ✗ pengguna.csv baris 8 (mahasiswa1.demo@…): NPM 130110240012 sudah dipakai akun annika…@mail.unpad.ac.id
    di jejak.pro. Bila orangnya sama, tambahkan baris "mahasiswa1.demo@…,annika…@mail.unpad.ac.id" ke
    jejak_pro/padanan_email.csv (kasus & nilainya ikut ke akun itu); bila bukan, perbaiki NPM-nya.

Kasus klinis           di paket 3 · baru 2 · diperbarui 0 · sudah ada 0 · GALAT 1
  ✗ kasus_klinis.csv baris 4: mahasiswa mahasiswa1.demo@… belum masuk karena baris penggunanya bermasalah
    (lihat langkah Pengguna).

Event asesmen          di paket 4 · baru 0 · ditautkan 0 · sudah ada 0 · GALAT 4
  ✗ daftar_event_asesmen.csv baris 2: event 'CBT Uji Coba' — periode '2026/2027 Ganjil' belum punya padanan.

Perbaiki yang ditandai ✗ lalu ulangi uji coba.
```

Setelah Kode Periode diisi di `periode.csv` dan satu baris ditambahkan ke `padanan_email.csv`, uji coba kedua:

```text
Periode akademik       di paket 1 · dipadankan 0 · lewat kode 1 · belum dipadankan 0
Pengguna               di paket 11 · baru 10 · diperbarui 0 · ditautkan/dilewati 1
  ! mahasiswa1.demo@… ditautkan ke akun jejak.pro annika…@mail.unpad.ac.id — data akun jejak.pro tidak diubah.
Rotasi klinik          di paket 3 · baru 3 · diperbarui 0 · dilewati/sudah ada 0
  ! Blok Klinis belum ada di master jejak.pro: Ilmu Penyakit Dalam, Ilmu Kesehatan Anak. …
Kasus klinis           di paket 3 · baru 3 · diperbarui 0 · sudah ada 0
Logbook kegiatan       di paket 3 · baru 3 · diperbarui 0 · sudah ada 0
Pemetaan kompetensi    di paket 19 · cocok nama 3 · lewat kode 0 · belum dipetakan 16
Event asesmen          di paket 4 · baru 4 · ditautkan 0 · sudah ada 0
Nilai asesmen          di paket 8 · baru 8 · diperbarui 0 · tidak berubah 0

Uji coba bersih. Jalankan ulang dengan COMMIT=1 untuk menyimpan.
```

### Cara membaca laporan

- **✗ galat** menghalangi penyimpanan. Perbaiki di CSV paket (atau siapkan data induknya di jejak.pro), lalu ulangi.
- **! peringatan** tidak menghalangi, tetapi layak diperiksa sebelum `COMMIT=1`.
- Galat turunan selalu menunjuk akarnya. Contohnya "belum masuk karena baris penggunanya bermasalah": cukup bereskan baris pengguna itu.
- Bila memang ingin menyimpan walau ada galat, tambahkan `PAKSA=1`. Baris yang bermasalah dilewati; impor ulang setelah diperbaiki akan melengkapinya.

### Aturan pemadanan (sengaja tidak menebak)

| Hal | Otomatis bila | Bila tidak |
| --- | --- | --- |
| Periode | jenis semester dan tahunnya sama di nama/kode ("2026/2027 Ganjil" = `ganjil_2026_2027`), **atau** rentang tanggal tumpang-tindih ≥ separuh | isi **Kode Periode jejak.pro**. Tanggal mulai saja tidak pernah cukup, karena itu yang dulu menempelkan data ke semester yang salah. |
| Kompetensi | nama sama, tanpa peduli huruf besar, tanda baca, spasi, dan "&"/"dan" | isi **Kode Kompetensi jejak.pro**. Tanpa itu nilai akhir tetap pindah, hanya rincian per kompetensinya yang tidak. |
| Pengguna | email sama (akun diperbarui) atau email baru (akun dibuat) | NPM/NIDN yang sudah dipakai akun lain **tidak digabung otomatis**. Tambahkan baris ke **padanan_email.csv**; akun jejak.pro tidak ditimpa, hanya kasus/nilai/rotasinya yang ikut. |
| Event asesmen | nama + periode sama → dipakai yang ada | dibuat baru dengan template dari `TEMPLATE_ID`/**ID Template jejak.pro**, atau tempel ke event yang ada lewat **ID Event jejak.pro** |
| Blok Klinis | nama sama dengan master jejak.pro | rotasi tetap masuk tanpa tautan blok, disertai peringatan. Tambahkan master bloknya **sebelum** `COMMIT=1`. |

## Pemetaan data

| jejak-lite | jejak.pro | Catatan |
| --- | --- | --- |
| User + peran | User (status) | mahasiswa → Mahasiswa; dosen+preseptor → Dosen (preceptor, tutor, penguji); preseptor → Dosen (preceptor, dokter di wahana pendidikan); dosen/kaprodi → Dosen; admin → Tenaga kependidikan. Peran admin/kaprodi ditetapkan ulang manual. |
| AcademicPeriod | AcademicPeriod | lihat aturan pemadanan |
| ClinicalRotation | ClinicalRotation | lewat `ClinicalRotationImporter`; stase → Blok Klinis, tempat → Wahana |
| ClinicalCase | ActivityLog (`practice`) + ActivityCaseDatum | status → verification_status; entrustment → involvement_level; setting & kelompok usia diterjemahkan ke kosakata jejak.pro; resep → `prescription`; poin pembelajaran → refleksi slot 1 |
| ActivityLog | ActivityLog (`practice`/`other`) | refleksi → refleksi slot 1 |
| AssessmentEvent | AssessmentEvent (status *closed*) | lihat aturan pemadanan |
| AssessmentInstance (+ dimensi, rubrik) | StudentAssessmentInstance (*finalized*) | `final_score` = persen 0–100; `competency_scores` = persen per kode kompetensi, dibaca Peta Kompetensi jejak.pro |
| CompetencyItem | CompetencyItem | lihat aturan pemadanan |

### Yang tidak dipindahkan otomatis

Semua data berikut tetap tersimpan di `data/*.json`, jadi tidak ada yang hilang. Hanya saja tidak ada padanan yang aman untuk dimasukkan otomatis:

- Isi rubrik penilaian per pertanyaan: yang pindah adalah nilainya per kompetensi, bukan lembar jawabannya.
- DOPS/Mini-CEX, keputusan entrustment, tugas akhir, jadwal evaluasi, blueprint, dan learning unit. Modul jejak.pro untuk ini lebih kaya, dan susunannya perlu diputuskan institusi.
- Notifikasi lama, sesi, token perangkat, dan kata sandi.
- Lampiran (`lampiran/`): diindeks di `lampiran.csv` dan dipasang manual bila diperlukan.

## Setelah impor

1. Cocokkan angka laporan dengan `manifest.json`.
2. Umumkan ke pengguna: mereka menerima email konfirmasi dan masuk lewat **Lupa Kata Sandi**.
3. Tetapkan peran admin, kaprodi, dan penguji di Peran & Akses.
4. Simpan paket (tanpa identitas pasien) sebagai arsip; hapus paket yang memuat identitas pasien.

## Untuk pengembang

Nama kolom `jejak_pro/*.csv` adalah kontrak antara `MigrationExporter` (jejak-lite, `app/services/migration_exporter.rb`) dan `JejakLiteBundleImporter` (jejak.pro, `app/services/jejak_lite_bundle_importer.rb` + `lib/tasks/jejak_lite.rake`). Keduanya punya tes (`test/services/migration_exporter_test.rb` di jejak-lite, `test/services/jejak_lite_bundle_importer_test.rb` di jejak.pro). Mengubah kolom berarti mengubah kedua sisi. Perubahan yang tidak kompatibel wajib menaikkan versi mayor `FORMAT_VERSION`; importer menolak versi mayor yang tidak dikenalnya.
