# Panduan Pengguna JEJAK Essential

JEJAK Essential adalah aplikasi pencatatan perjalanan belajar klinis yang berdiri sendiri: logbook kegiatan, logbook kasus klinis, rotasi klinik dan enrolment tutorial, asesmen (DOPS, Mini-CEX, ujian tulis/praktik, rubrik penguji, CBD/Long Case), pemetaan capaian kompetensi & EPA, tugas akhir, serta dashboard analitik untuk pembimbing dan program studi.

Panduan ini disusun menurut **peran**: bab awal berlaku untuk semua orang, lalu bab khusus mahasiswa, bab khusus pembimbing (dosen, preseptor, kaprodi), dan bab khusus admin. Bagian akhir memuat catatan privasi data pasien, notifikasi, pertanyaan yang sering diajukan, dan daftar alamat halaman.

> **Cara membaca panduan ini.** Nama menu ditulis **tebal** persis seperti di sidebar (mis. **Logbook → Kasus Klinis**). Alamat halaman ditulis dengan huruf mesin, mis. `/clinical_cases`. Bila admin instansi Anda mengganti label menu lewat **Taksonomi Istilah**, nama yang Anda lihat bisa berbeda dari yang tertulis di sini — alamat halamannya tetap sama.

## Daftar Isi

<!-- TOC:START -->
- [Bab 1 — Memulai](#bab-1--memulai)
  - [1.1 Mendaftar akun](#mendaftar-akun)
  - [1.2 Masuk, lupa kata sandi, keluar](#masuk-lupa-kata-sandi-keluar)
  - [1.3 Melengkapi profil](#melengkapi-profil)
- [Bab 2 — Mengenal Antarmuka](#bab-2--mengenal-antarmuka)
  - [2.1 Anatomi layar](#anatomi-layar)
  - [2.2 Grup menu sidebar](#grup-menu-sidebar)
  - [2.3 Ganti peran](#ganti-peran)
  - [2.4 Tema, ukuran huruf, dan bahasa](#tema-ukuran-huruf-dan-bahasa)
  - [2.5 Pencarian](#pencarian)
  - [2.6 Notifikasi](#notifikasi)
- [Bab 3 — Peran dan Hak Akses](#bab-3--peran-dan-hak-akses)
- [Bab 4 — Panduan Mahasiswa](#bab-4--panduan-mahasiswa)
  - [4.1 Beranda mahasiswa](#beranda-mahasiswa)
  - [4.2 Logbook Kegiatan](#logbook-kegiatan)
  - [4.3 Logbook Kasus Klinis](#logbook-kasus-klinis)
  - [4.4 Longitudinal Portfolio](#longitudinal-portfolio)
  - [4.5 Rotasi Klinik dan Enrolment Tutorial](#rotasi-klinik-dan-enrolment-tutorial)
  - [4.6 Refleksi](#refleksi)
  - [4.7 Tugas Akhir](#tugas-akhir)
  - [4.8 Evaluasi Akademik (nilai ujian)](#evaluasi-akademik-nilai-ujian)
  - [4.9 Workplace Assessment (DOPS & Mini-CEX)](#workplace-assessment-dops--mini-cex)
  - [4.10 Rubric-based Assessment (Asesmen Saya)](#rubric-based-assessment-asesmen-saya)
  - [4.11 Jurnal Umpan Balik](#jurnal-umpan-balik)
  - [4.12 Formulir evaluasi (Assessment Form)](#formulir-evaluasi-assessment-form)
  - [4.13 Peta Kompetensi (Analisis Capaian Pembelajaran)](#peta-kompetensi-analisis-capaian-pembelajaran)
  - [4.14 Peta EPA & Tingkat Entrustment](#peta-epa--tingkat-entrustment)
- [Bab 5 — Panduan Pembimbing (Dosen, Preseptor, Kaprodi)](#bab-5--panduan-pembimbing-dosen-preseptor-kaprodi)
  - [5.1 Beranda pembimbing](#beranda-pembimbing)
  - [5.2 Validasi Kasus Klinis](#validasi-kasus-klinis)
  - [5.3 Validasi Kegiatan](#validasi-kegiatan)
  - [5.4 Menilai DOPS dan Mini-CEX](#menilai-dops-dan-mini-cex)
  - [5.5 Lembar Penguji (rubrik, CBD, Long Case)](#lembar-penguji-rubrik-cbd-long-case)
  - [5.6 Tugas Akhir: membimbing dan menguji](#tugas-akhir-membimbing-dan-menguji)
  - [5.7 Memutuskan tingkat EPA](#memutuskan-tingkat-epa)
  - [5.8 Dashboard Analitik](#dashboard-analitik)
  - [5.9 Daftar Mahasiswa](#daftar-mahasiswa)
  - [5.10 Khusus kaprodi](#khusus-kaprodi)
- [Bab 6 — Panduan Admin (Konfigurasi)](#bab-6--panduan-admin-konfigurasi)
  - [6.1 Tahun/Periode Akademik](#tahunperiode-akademik)
  - [6.2 Program Studi](#program-studi)
  - [6.3 Pengguna & impor CSV](#pengguna--impor-csv)
  - [6.4 Relabel Prodi Mahasiswa](#relabel-prodi-mahasiswa)
  - [6.5 Assessment Events dan impor nilai](#assessment-events-dan-impor-nilai)
  - [6.6 Jadwal DOPS & Mini-CEX](#jadwal-dops--mini-cex)
  - [6.7 Kerangka Kompetensi](#kerangka-kompetensi)
  - [6.8 Blueprint Asesmen](#blueprint-asesmen)
  - [6.9 Learning Unit & Matrix](#learning-unit--matrix)
  - [6.10 Target Kasus Logbook](#target-kasus-logbook)
  - [6.11 Domain Kegiatan Akademik](#domain-kegiatan-akademik)
  - [6.12 Master Diagnosis, Keterampilan, Obat](#master-diagnosis-keterampilan-obat)
  - [6.13 Assessment Form Builder (templat formulir)](#assessment-form-builder-templat-formulir)
  - [6.14 Rotasi Klinik dan Enrolment Tutorial](#rotasi-klinik-dan-enrolment-tutorial-1)
  - [6.15 Taksonomi Istilah](#taksonomi-istilah)
  - [6.16 Data Governance](#data-governance)
- [Bab 7 — Privasi & Keamanan Data Pasien](#bab-7--privasi--keamanan-data-pasien)
- [Bab 8 — Notifikasi](#bab-8--notifikasi)
- [Bab 9 — Bagaimana Data Mengalir ke Capaian](#bab-9--bagaimana-data-mengalir-ke-capaian)
- [Bab 10 — Pertanyaan yang Sering Diajukan](#bab-10--pertanyaan-yang-sering-diajukan)
- [Bab 11 — Pindah ke jejak.pro](#bab-11--pindah-ke-jejakpro)
- [Lampiran A — Daftar Alamat Halaman](#lampiran-a--daftar-alamat-halaman)
- [Lampiran B — Glosarium](#lampiran-b--glosarium)
<!-- TOC:END -->

---

## Bab 1 — Memulai

### 1.1 Mendaftar akun

1. Buka halaman muka aplikasi, lalu klik **Daftar**.
2. Isi **Nama Lengkap**, **Email**, pilih **Peran** (Mahasiswa, Dosen, atau Preseptor), lalu buat **Kata Sandi** dan ulangi.
3. Klik **Daftar**. Peran yang Anda pilih langsung menjadi peran aktif akun Anda.

Peran **Kaprodi** dan **Admin** tidak dapat dipilih sendiri karena membuka data seluruh prodi/instalasi — admin instansi yang memberikannya lewat **Konfigurasi → Pengguna → Sunting** (atau kolom `peran` pada impor CSV). Permintaan peran itu lewat form yang diubah pun ditolak dan akun tetap menjadi Mahasiswa.

Bila instansi Anda mengaktifkan login Google, tombol **Masuk dengan Google** juga tersedia — akun Google baru otomatis dibuat sebagai pengguna dan dianggap sudah terverifikasi.

> **Konfirmasi email.** Konfirmasi lewat surel hanya diminta bila server dipasangi layanan pengirim email. Pada instalasi tanpa server surat, akun hasil pendaftaran langsung bisa dipakai. Jika Anda mendapat pesan "harus mengonfirmasi email" padahal tidak pernah menerima suratnya, minta admin membuka **Konfigurasi → Pengguna → Sunting → Konfirmasi Sekarang**.

Sebagian instansi tidak membuka pendaftaran mandiri dan memilih **mengimpor akun dari CSV** (lihat [Pengguna & impor CSV](#pengguna--impor-csv)). Akun hasil impor memakai kata sandi bawaan `password123` — segera ganti lewat **Pengaturan Akun** setelah masuk pertama kali.

### 1.2 Masuk, lupa kata sandi, keluar

- **Masuk**: email + kata sandi, atau tombol Google. Centang **Ingat saya** agar tidak perlu masuk ulang di perangkat yang sama.
- **Lupa kata sandi**: tautan *Lupa kata sandi?* di halaman masuk mengirim tautan reset ke email Anda (hanya tampil bila server bisa mengirim email). Tanpa server surat, admin dapat me-reset kata sandi Anda ke bawaan dari **Konfigurasi → Pengguna**.
- **Ganti kata sandi / email**: menu akun (pojok kanan atas) → **Pengaturan Saya** → tautan **Pengaturan Akun**, atau langsung ke `/users/edit`. Ubah **Email** dan/atau isi **Kata Sandi Baru** + **Ulangi Kata Sandi Baru** (kosongkan bila tidak ingin mengganti), lalu isi **Kata Sandi Saat Ini** — wajib untuk menyimpan perubahan apa pun di halaman itu. Pada instalasi yang mengirim email, email baru berlaku setelah tautan konfirmasi yang dikirim ke alamat baru dibuka.
- **Keluar**: menu akun → **Keluar**.

### 1.3 Melengkapi profil

Buka **Ikhtisar → Profil Saya** (`/profile`) lalu **Sunting Profil**. Halaman profil menampilkan **persentase kelengkapan** dan daftar isian yang belum diisi — daftar itu berbeda per peran:

| Bagian | Isian | Wajib untuk |
|---|---|---|
| Foto & Akun | Foto profil, Nama Lengkap, Email (hanya dibaca), NPM/NIM atau NIP/NIDN | semua |
| Biodata Pribadi | Nomor Telepon / WhatsApp, Jenis Kelamin, Tempat & Tanggal Lahir, Alamat Domisili | semua (telepon, jenis kelamin, tanggal lahir) |
| Akademik | Program Studi, Angkatan | mahasiswa |
| Informasi Kepegawaian | Unit Kerja / Departemen, Jabatan, Kategori Profesi, Spesialisasi, Program Studi Binaan | dosen / preseptor / kaprodi / admin |

**Program Studi sangat penting bagi mahasiswa**: ia menentukan event asesmen mana yang tampil untuk Anda, target kasus logbook, Learning Unit, kurva persentil kohort, dan tampilan Anda di Dashboard Analitik kaprodi. Program studi tersedia dua: **Sarjana Kedokteran (pssk)** dan **Profesi Dokter (pspd)** — admin dapat menambah lainnya.

Bagi **kaprodi**, isian **Program Studi Binaan** hanya ditampilkan dan tidak dapat diubah sendiri, karena prodi itulah batas hak akses kaprodi (Dashboard Analitik bagian *Program Studi* dan Relabel Prodi). Admin menetapkannya lewat **Konfigurasi → Pengguna → Sunting**.

---

## Bab 2 — Mengenal Antarmuka

### 2.1 Anatomi layar

<svg class="dg" viewBox="0 0 760 400" role="img" aria-label="Anatomi layar: sidebar kiri, topbar, area konten, bilah bawah ponsel">
  <rect x="10" y="10" width="740" height="330" rx="10" class="dg-frame"/>
  <rect x="10" y="10" width="190" height="330" rx="10" class="dg-dark"/>
  <text x="105" y="38" class="dg-tw dg-b" text-anchor="middle">JEJAK</text>
  <text x="105" y="52" class="dg-tw dg-s" text-anchor="middle">Nama prodi Anda</text>
  <line x1="20" y1="62" x2="190" y2="62" class="dg-line-w"/>
  <circle cx="36" cy="82" r="10" class="dg-accent"/>
  <text x="52" y="80" class="dg-tw dg-s">Nama Anda</text>
  <text x="52" y="92" class="dg-tw dg-s">Peran aktif</text>
  <rect x="20" y="102" width="170" height="16" rx="4" class="dg-dark2"/>
  <text x="105" y="114" class="dg-tw dg-s" text-anchor="middle">Edit Profil</text>
  <rect x="20" y="126" width="170" height="16" rx="4" class="dg-dark2"/>
  <text x="28" y="138" class="dg-tw dg-s">Cari menu…</text>
  <text x="24" y="162" class="dg-tw dg-s dg-b">IKHTISAR</text>
  <text x="30" y="176" class="dg-tw dg-s">Beranda · Portfolio · Profil · Notifikasi</text>
  <text x="24" y="196" class="dg-tw dg-s dg-b">PERJALANAN BELAJAR</text>
  <text x="30" y="210" class="dg-tw dg-s" textLength="158" lengthAdjust="spacingAndGlyphs">Logbook ▾ · Rotasi · Tutorial · Refleksi · TA</text>
  <text x="24" y="230" class="dg-tw dg-s dg-b">ASESMEN</text>
  <text x="30" y="244" class="dg-tw dg-s">Asesmen &amp; Evaluasi ▾</text>
  <text x="24" y="264" class="dg-tw dg-s dg-b">KOMPETENSI &amp; PRESTASI</text>
  <text x="24" y="284" class="dg-tw dg-s dg-b">COACHING CENTER · KONFIGURASI</text>
  <line x1="20" y1="300" x2="190" y2="300" class="dg-line-w"/>
  <text x="30" y="318" class="dg-tw dg-s">Panduan · Pengaturan · Keluar</text>
  <rect x="200" y="10" width="550" height="44" class="dg-topbar"/>
  <text x="212" y="36" class="dg-t dg-b">☰  Judul halaman</text>
  <rect x="380" y="20" width="90" height="24" rx="6" class="dg-box-gray"/>
  <text x="425" y="36" class="dg-ts" text-anchor="middle">Peran aktif ▾</text>
  <rect x="478" y="20" width="70" height="24" rx="6" class="dg-box-gray"/>
  <text x="513" y="36" class="dg-ts" text-anchor="middle">Cari…</text>
  <text x="565" y="36" class="dg-ts">☼</text>
  <text x="588" y="36" class="dg-ts">EN</text>
  <text x="616" y="36" class="dg-ts">?</text>
  <text x="640" y="36" class="dg-ts">🔔</text>
  <circle cx="700" cy="32" r="11" class="dg-accent"/>
  <text x="700" y="36" class="dg-tw dg-s" text-anchor="middle">A</text>
  <rect x="215" y="70" width="520" height="255" rx="8" class="dg-box"/>
  <text x="475" y="180" class="dg-t" text-anchor="middle">Area konten halaman</text>
  <text x="475" y="198" class="dg-ts" text-anchor="middle">(kartu, tabel, formulir, grafik)</text>
  <rect x="10" y="352" width="740" height="38" rx="8" class="dg-box-gray"/>
  <text x="80" y="375" class="dg-ts" text-anchor="middle">Beranda</text>
  <text x="230" y="375" class="dg-ts" text-anchor="middle">Log Keg.</text>
  <text x="380" y="375" class="dg-ts" text-anchor="middle">Log Kasus</text>
  <text x="530" y="375" class="dg-ts" text-anchor="middle">Verifikasi / Asesmen</text>
  <text x="680" y="375" class="dg-ts" text-anchor="middle">Profil</text>
  <text x="745" y="349" class="dg-lbl" text-anchor="end">↓ Bilah bawah (hanya di ponsel)</text>
</svg>

| Bagian | Isi |
|---|---|
| **Sidebar** (kiri, gelap) | Merek + nama prodi, identitas & **peran aktif**, tombol **Edit Profil**, kotak **Cari menu** (menyaring menu saat mengetik), grup menu, dan di kaki: **Panduan Pengguna**, **Pengaturan**, **Keluar**. Di ponsel sidebar tersembunyi; buka dengan tombol ☰. |
| **Topbar** (atas, putih) | Judul halaman, pengalih **Peran aktif**, kotak **Cari** (menuju halaman Pencarian), tombol **tema** (terang → gelap → ikuti sistem), tombol bahasa **EN/ID**, tombol **?** (membuka panduan ini di tab baru), **lonceng notifikasi** (5 terbaru + lencana belum dibaca), dan **menu akun** (Profil Saya, Pengaturan Saya, Keluar). |
| **Area konten** | Halaman yang sedang dibuka. |
| **Bilah bawah** (ponsel) | Lima pintasan: Beranda, Log Kegiatan, Log Kasus, Verifikasi (pembimbing) atau Asesmen (mahasiswa), Profil. |

### 2.2 Grup menu sidebar

Sidebar hanya memuat enam grup, dan **menyempit mengikuti peran aktif** — bukan gabungan semua peran yang Anda miliki.

| Grup | Menu | Tampil untuk |
|---|---|---|
| **Ikhtisar** | Beranda, Longitudinal Portfolio (mahasiswa), Profil Saya, Notifikasi | semua |
| **Perjalanan Belajar** | Logbook ▾ (Kasus Klinis, Logbook Kegiatan), Rotasi Klinik, Enrolment Tutorial, Refleksi, Tugas Akhir | semua |
| **Asesmen** | Asesmen & Evaluasi ▾ (Evaluasi Akademik, Workplace Assessment, Rubric-based Assessment, Jurnal Umpan Balik*, Assessment Form Builder†) | semua (*Jurnal hanya mahasiswa; †Form Builder hanya kaprodi & admin) |
| **Kompetensi & Prestasi** | Peta Kompetensi, Peta EPA & Entrustment | semua |
| **Coaching Center** | Validasi Kasus Klinis, Validasi Kegiatan, Dashboard Analitik, Daftar Mahasiswa, Relabel Prodi Mahasiswa (kaprodi) | peran aktif dosen / preseptor / kaprodi / admin |
| **Konfigurasi** | 17 menu pengelolaan (lihat [Bab 6](#bab-6--panduan-admin-konfigurasi)) | akun yang **memiliki** peran admin, apa pun peran aktifnya |

Lencana angka di **Validasi Kasus Klinis** dan **Validasi Kegiatan** menunjukkan jumlah butir yang menunggu verifikasi.

### 2.3 Ganti peran

Satu akun dapat menyandang beberapa peran (mis. dosen yang juga preseptor, atau mahasiswa yang juga admin). Pilih peran pada dropdown **Peran aktif** di topbar; sidebar, beranda, dan bilah bawah ikut menyesuaikan. Peran aktif hanya mengubah **apa yang ditawarkan** — hak akses tiap halaman tetap diperiksa dari seluruh peran yang Anda miliki, sehingga:

- akun multi-peran **tidak bisa memverifikasi kasus atau kegiatannya sendiri**;
- grup **Konfigurasi** tampil selama akun memiliki peran admin, walau peran aktifnya mahasiswa.

### 2.4 Tema, ukuran huruf, dan bahasa

Buka **Pengaturan Saya** (`/pengaturan`) dari kaki sidebar atau menu akun:

- **Mode warna**: Terang, Gelap, atau Ikuti sistem. Tombol ☼ di topbar juga menggilirnya.
- **Ukuran huruf**: Kecil, Normal, Besar — seluruh antarmuka ikut berubah proporsional.
- **Bahasa antarmuka**: Bahasa Indonesia atau English. Tombol **EN/ID** di topbar mengganti bahasa secara langsung. Cakupannya **hanya cangkang** (sidebar, topbar, bilah bawah, halaman masuk/daftar, Pengaturan Saya); isi halaman tetap berbahasa Indonesia.

Preferensi disimpan pada akun, jadi berlaku di semua perangkat.

### 2.5 Pencarian

Kotak **Cari** di topbar dan menu **Daftar Mahasiswa** (`/cari`) mencari **pengguna** berdasarkan nama atau email. Kartu hasil dapat diklik untuk membuka profil pengguna. Pencarian belum mencakup isi logbook atau kasus.

### 2.6 Notifikasi

Halaman **Ikhtisar → Notifikasi** (`/notifications`) memuat semua pemberitahuan: kasus diverifikasi/perlu revisi/ditolak, kegiatan diverifikasi, DOPS/Mini-CEX baru, nilai keluar, permintaan penilaian, komentar kasus, tingkat entrustment diperbarui, skor ujian tugas akhir, dan jadwal. Tiap butir bisa **ditandai dibaca** atau **diarsipkan**; tombol **Tandai semua dibaca** membersihkan lencana sekaligus.

**Notifikasi push** (opsional, bila server dipasangi kunci VAPID): klik **Aktifkan Notifikasi Push** dan izinkan di peramban. Di iPhone, fitur ini hanya bekerja setelah aplikasi ditambahkan ke Layar Utama. Lihat juga [Bab 8](#bab-8--notifikasi).

---

## Bab 3 — Peran dan Hak Akses

| Peran | Fungsi utama | Yang boleh dilakukan |
|---|---|---|
| **Mahasiswa** | Mencatat perjalanan belajar | Mencatat kegiatan & kasus, mengajukan verifikasi, meminta DOPS/Mini-CEX/CBD/Long Case dari kasus, mendaftar & mengumpulkan asesmen rubrik, menulis refleksi, mendaftarkan tugas akhir, melihat nilai, capaian, dan peta EPA miliknya sendiri. |
| **Dosen** | Pembimbing akademik, tutor, penguji | Memverifikasi kasus (yang menandainya atau tanpa tanda pembimbing) & kegiatan mahasiswa mana pun, menilai DOPS/Mini-CEX, menilai di Lembar Penguji, memberi skor tugas akhir, memutuskan tingkat EPA bagi mahasiswa yang berelasi, Dashboard Analitik bagian *Mahasiswa Bimbingan*. |
| **Preseptor** | Pembimbing klinis di wahana | Setara dosen untuk verifikasi & penilaian; menjadi penilai bawaan DOPS/Mini-CEX yang diminta dari kasus pada rotasinya; Dashboard Analitik bagian *Mahasiswa di Wahana Anda*. |
| **Kaprodi** | Pemantau program studi | Membuka halaman mahasiswa lain (hanya melihat, tidak menilai), Dashboard Analitik bagian *Program Studi* (terkunci ke prodi binaan yang ditetapkan admin), Relabel Prodi Mahasiswa, Jadwal DOPS & Mini-CEX, Learning Unit & Matrix, **Assessment Form Builder** (kelola penuh). |
| **Admin** | Pengelola instalasi | Semua hal di atas ditambah seluruh grup **Konfigurasi**: pengguna, periode, prodi, event asesmen, kurikulum, master data, taksonomi, istilah, dan tata kelola data. |

Aturan yang berlaku lintas peran:

- **Kepemilikan**: mahasiswa hanya melihat data miliknya; pembimbing dapat membuka kasus/kegiatan siapa pun (untuk verifikasi) dan DOPS/Mini-CEX/tugas akhir yang berkaitan dengannya; admin melihat semuanya.
- **Anti-konflik**: verifikasi kasus/kegiatan tidak bisa dilakukan atas data milik sendiri, kasus yang menandai pembimbing hanya bisa diverifikasi pembimbing itu, dan hanya verifier asal atau admin yang boleh **membatalkan** verifikasi.
- **Relasi pembimbingan** (dipakai Peta EPA & Dashboard Analitik): seseorang dianggap membimbing mahasiswa bila pernah menilai DOPS/Mini-CEX-nya, membimbing tugas akhirnya, memverifikasi kasusnya, menjadi tutor enrolmennya, atau preseptor rotasinya.

---

## Bab 4 — Panduan Mahasiswa

### 4.1 Beranda mahasiswa

Beranda (`/dashboard`) mengikuti pola beranda jejak.pro, dari atas ke bawah:

- **Sapaan** dengan peran aktif, prodi, angkatan, dan jam WIB, lalu kartu **Sponsor Pengembangan** (AIPKI).
- **Agenda Mendatang** (7 hari ke depan; tampil bila ada isinya): rotasi klinik dan blok tutorial yang akan dimulai/berakhir, jadwal DOPS/Mini-CEX, ujian dan batas pengumpulan asesmen rubrik, tenggat milestone tugas akhir, serta kegiatan terjadwal di Kalender. Lima terdekat ditampilkan, sisanya diringkas "+N agenda lainnya".
- **Kasus diminta diperbaiki**: kasus yang dikembalikan preseptor (status *Perlu Revisi*), lengkap dengan nama peminta.
- **Kasus masih draft**: draft hanya terlihat oleh Anda; preseptor baru menerimanya setelah Anda menekan **Kirim untuk Verifikasi**.
- **Pengingat pencatatan kasus**: muncul bila Anda sedang berotasi dan **2 hari** tidak mencatat kasus baru.
- **Tahap studi** (Pre-Klinik/Sarjana → Klinik/Profesi, dari jenjang prodi Anda), kartu **fokus yang sedang berjalan** (rotasi atau blok aktif, preseptor/tutor, jumlah kegiatan bulan ini, kasus terverifikasi, refleksi, dan tombol Catat Kasus/Kegiatan/Tulis Refleksi), serta **Kelengkapan Profil**.
- **Perhatian Akademik**: muncul bila dalam 30 hari terakhir ada kasus yang diverifikasi dengan **rekomendasi remediasi**, atau rata-rata DOPS/Mini-CEX Anda **di bawah 4** (skala 1–9).
- **Pusat Asesmen & Capaian**: enam kartu pintasan — Evaluasi Akademik (dengan lencana jumlah asesmen menunggu), Workplace Assessment, Rubric-based Assessment, Jurnal Umpan Balik, Peta Kompetensi, Peta EPA.
- **Radar kompetensi** rata-rata dimensi DOPS & Mini-CEX Anda (bila sudah ada evaluasi terkirim), lalu kartu informasi peningkatan ke jejak.pro (bisa diciutkan).

Notifikasi yang belum dibaca ada di ikon lonceng topbar.

### 4.2 Logbook Kegiatan

Menu **Logbook → Logbook Kegiatan** (`/activity_logs`) mencatat kegiatan **bukan-kasus**: kuliah, tutorial, jaga, praktikum, seminar, kompetisi, pengabdian, dan sebagainya.

#### Taksonomi kegiatan

Setiap kegiatan digolongkan tiga tingkat, mengikuti daftar yang dikelola admin:

<svg class="dg" viewBox="0 0 760 210" role="img" aria-label="Taksonomi kegiatan tiga tingkat: Domain, Subdomain, Bentuk Kegiatan">
  <defs><marker id="ar-tax" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <text x="110" y="24" class="dg-lbl dg-b" text-anchor="middle">1. Domain Kegiatan</text>
  <text x="380" y="24" class="dg-lbl dg-b" text-anchor="middle">2. Subdomain / Kategori</text>
  <text x="650" y="24" class="dg-lbl dg-b" text-anchor="middle">3. Bentuk Kegiatan (opsional)</text>
  <rect x="20" y="40" width="180" height="44" rx="8" class="dg-box"/>
  <text x="110" y="60" class="dg-t dg-b" text-anchor="middle">Belajar Mengajar</text>
  <text x="110" y="76" class="dg-ts" text-anchor="middle">non-klinis</text>
  <rect x="290" y="40" width="180" height="44" rx="8" class="dg-box"/>
  <text x="380" y="66" class="dg-t" text-anchor="middle">Tutorial</text>
  <line x1="200" y1="62" x2="288" y2="62" class="dg-arrow" marker-end="url(#ar-tax)"/>
  <rect x="20" y="110" width="180" height="44" rx="8" class="dg-box-green"/>
  <text x="110" y="130" class="dg-t dg-b" text-anchor="middle">Prestasi Kemahasiswaan</text>
  <text x="110" y="146" class="dg-ts" text-anchor="middle">non-klinis</text>
  <rect x="290" y="110" width="180" height="44" rx="8" class="dg-box-green"/>
  <text x="380" y="136" class="dg-t" text-anchor="middle">Kompetisi</text>
  <rect x="560" y="110" width="180" height="44" rx="8" class="dg-box-green"/>
  <text x="650" y="136" class="dg-t" text-anchor="middle">Juara-1 Perorangan</text>
  <line x1="200" y1="132" x2="288" y2="132" class="dg-arrow" marker-end="url(#ar-tax)"/>
  <line x1="470" y1="132" x2="558" y2="132" class="dg-arrow" marker-end="url(#ar-tax)"/>
  <rect x="20" y="170" width="180" height="30" rx="8" class="dg-box-amber"/>
  <text x="110" y="189" class="dg-t" text-anchor="middle">Praktek</text>
  <text x="215" y="189" class="dg-ts">domain bertanda "kegiatan klinis" → dihitung Klinis di Portfolio</text>
</svg>

Domain yang ditandai admin sebagai *kegiatan klinis* membuat kegiatan itu dihitung sebagai **Klinis** di Portfolio dan kode pasien; selainnya **Non-Klinis**.

#### Mencatat kegiatan

1. Klik **+ Catat Kegiatan**.
2. Pilih **Domain Kegiatan** (wajib). Pilihan **Subdomain / Kategori** menyesuaikan domain, dan **Bentuk Kegiatan** muncul bila kategori itu punya rincian. Pilihan yang sudah dinonaktifkan admin tidak dapat dipilih baru.
3. Isi **Topik Kegiatan** (wajib), **Waktu Mulai** (wajib) dan Waktu Selesai, **Metode Pelaksanaan** Luring/Daring (wajib).
4. Lengkapi bila ada: Lokasi, **Rotasi Klinik/Wahana** (dari rotasi Anda sendiri), **Semester** (terisi otomatis bila tepat satu periode akademik mencakup tanggalnya), Catatan, Refleksi, Jumlah peserta, **Kompetensi** (centang ranah/sub-kompetensi dari Kerangka Kompetensi), serta **Dokumen & Bukti**: tautan bukti, tautan dokumen, dan unggahan berkas.
5. Klik simpan. Saat menyunting, unggahan baru **ditambahkan** ke lampiran lama, bukan menggantikannya.

#### Daftar, filter, dan Kalender

- Tab **Punya Saya** menampilkan kegiatan Anda dalam **linimasa per tanggal**. Chip filter **domain** dan **kompetensi** menyaring daftar; **✕ Hapus filter** mengembalikannya.
- Sakelar **Daftar | Kalender** mengganti tampilan ke **kalender bulanan** (`/kalender`, navigasi ‹ › antar bulan). Kegiatan yang sudah diverifikasi diberi penanda warna berbeda.
- **Feed Kalender (iCal)** di bawah kalender: salin alamatnya ke Google Calendar/Outlook/Apple Calendar agar kegiatan Anda muncul di kalender pribadi. Alamat itu adalah kredensial — jika bocor, klik **Perbarui Tautan** dan tautan lama langsung tidak berlaku.
- Tombol **Buat Kode Pasien** pada halaman kegiatan klinis (hanya untuk pemilik kegiatan) membuat kode acak non-identifikasi (mis. `P-7K2M9QXA`) untuk menandai beberapa kegiatan dengan pasien yang sama tanpa menyimpan data pribadi.
- Kegiatan Anda dapat dihapus dari halaman kegiatannya. Refleksi yang menautkan kegiatan itu tetap tersimpan; hanya tautannya yang dilepas.

#### Verifikasi kegiatan

Kegiatan tersimpan dengan status *belum diverifikasi*. Pembimbing membukanya lewat **Validasi Kegiatan** dan menekan **Verifikasi**; Anda menerima notifikasi, kegiatan berpenanda ✓ di daftar dan kalender. Kegiatan lama (dicatat sebelum taksonomi ada) tetap tampil sebagai Klinis/Non-Klinis; saat disunting Anda diminta memilih domain.

### 4.3 Logbook Kasus Klinis

Menu **Logbook → Kasus Klinis** (`/clinical_cases`). Halaman daftar memuat **statistik** (jumlah per status, 5 diagnosis terbanyak), kartu **Pemenuhan Target Kasus** FKTP/FKRTL (bila admin menetapkan target untuk prodi Anda; hanya kasus **terverifikasi** yang dihitung), dan daftar kasus Anda.

#### Wizard 6 langkah

<svg class="dg" viewBox="0 0 760 150" role="img" aria-label="Wizard kasus klinis enam langkah">
  <defs><marker id="ar-wiz" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <g>
    <rect x="10" y="30" width="110" height="70" rx="8" class="dg-box"/>
    <circle cx="65" cy="20" r="11" class="dg-accent"/><text x="65" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">1</text>
    <text x="65" y="58" class="dg-ts dg-b" text-anchor="middle">Identitas &amp;</text><text x="65" y="72" class="dg-ts dg-b" text-anchor="middle">Demografi</text>
    <text x="65" y="90" class="dg-ts" text-anchor="middle">tgl, keluhan*, pasien</text>
  </g>
  <line x1="120" y1="65" x2="136" y2="65" class="dg-arrow" marker-end="url(#ar-wiz)"/>
  <g>
    <rect x="138" y="30" width="110" height="70" rx="8" class="dg-box"/>
    <circle cx="193" cy="20" r="11" class="dg-accent"/><text x="193" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">2</text>
    <text x="193" y="58" class="dg-ts dg-b" text-anchor="middle">Anamnesis, PF</text><text x="193" y="72" class="dg-ts dg-b" text-anchor="middle">&amp; Tanda Vital</text>
    <text x="193" y="90" class="dg-ts" text-anchor="middle">BMI otomatis</text>
  </g>
  <line x1="248" y1="65" x2="264" y2="65" class="dg-arrow" marker-end="url(#ar-wiz)"/>
  <g>
    <rect x="266" y="30" width="110" height="70" rx="8" class="dg-box"/>
    <circle cx="321" cy="20" r="11" class="dg-accent"/><text x="321" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">3</text>
    <text x="321" y="58" class="dg-ts dg-b" text-anchor="middle">Pemeriksaan</text><text x="321" y="72" class="dg-ts dg-b" text-anchor="middle">Penunjang</text>
    <text x="321" y="90" class="dg-ts" text-anchor="middle">lab, radiologi, lain</text>
  </g>
  <line x1="376" y1="65" x2="392" y2="65" class="dg-arrow" marker-end="url(#ar-wiz)"/>
  <g>
    <rect x="394" y="30" width="110" height="70" rx="8" class="dg-box"/>
    <circle cx="449" cy="20" r="11" class="dg-accent"/><text x="449" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">4</text>
    <text x="449" y="58" class="dg-ts dg-b" text-anchor="middle">Diagnosis &amp;</text><text x="449" y="72" class="dg-ts dg-b" text-anchor="middle">Tatalaksana</text>
    <text x="449" y="90" class="dg-ts" text-anchor="middle">ICD-10/SKDI otomatis</text>
  </g>
  <line x1="504" y1="65" x2="520" y2="65" class="dg-arrow" marker-end="url(#ar-wiz)"/>
  <g>
    <rect x="522" y="30" width="110" height="70" rx="8" class="dg-box"/>
    <circle cx="577" cy="20" r="11" class="dg-accent"/><text x="577" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">5</text>
    <text x="577" y="58" class="dg-ts dg-b" text-anchor="middle">Terapi &amp;</text><text x="577" y="72" class="dg-ts dg-b" text-anchor="middle">Resep</text>
    <text x="577" y="90" class="dg-ts" text-anchor="middle">resep terstruktur</text>
  </g>
  <line x1="632" y1="65" x2="648" y2="65" class="dg-arrow" marker-end="url(#ar-wiz)"/>
  <g>
    <rect x="650" y="30" width="100" height="70" rx="8" class="dg-box-green"/>
    <circle cx="700" cy="20" r="11" class="dg-accent"/><text x="700" y="24" class="dg-tw dg-s dg-b" text-anchor="middle">6</text>
    <text x="700" y="58" class="dg-ts dg-b" text-anchor="middle">Pembelajaran</text><text x="700" y="72" class="dg-ts dg-b" text-anchor="middle">&amp; Bukti</text>
    <text x="700" y="90" class="dg-ts" text-anchor="middle">unggah berkas</text>
  </g>
  <text x="380" y="130" class="dg-lbl" text-anchor="middle">Penanda langkah dapat diklik untuk melompat. Simpan Draf tersedia di langkah mana pun; galat validasi menunjuk langkah yang bermasalah.</text>
</svg>

| Langkah | Isian |
|---|---|
| 1. Identitas & Demografi | Tanggal kasus*, Keluhan utama*, kelompok usia (Anak/Dewasa/Lansia), jenis kelamin, **usia** dan **pekerjaan** pasien (tidak sensitif, tampil terbuka), setting klinis (Rawat Jalan, Rawat Inap, IGD, ICU, Kamar Operasi, Pelayanan Primer), kompleksitas (Rendah/Sedang/Tinggi), blok **Identitas Pasien** (nama, No. RM, tanggal lahir, telepon, alamat) yang disimpan **terenkripsi**, dan **Dosen/Preseptor Pembimbing** (opsional — lihat di bawah). |
| 2. Anamnesis, PF & Tanda Vital | Anamnesis, keadaan umum, pemeriksaan fisik, riwayat keluarga, tanda vital (suhu, TD, nadi, respirasi, BB, TB) — **BMI** dihitung otomatis. |
| 3. Pemeriksaan Penunjang | Hasil laboratorium, radiologi, pemeriksaan lain. |
| 4. Diagnosis & Tatalaksana | Diagnosis (isian ber-autocomplete dari **Master Diagnosis**; kode ICD-10 dan level SKDI terisi otomatis bila cocok) dan tatalaksana. |
| 5. Terapi & Resep | Latihan menulis resep: nama obat (autocomplete dari **Master Obat**), sediaan, kekuatan, jumlah, rute, aturan pakai (signa), catatan. Baris yang sama sekali kosong dibuang otomatis; baris terisi sebagian tanpa nama obat ditandai dan harus dilengkapi. **Pratinjau resep** langsung menyusun isian menjadi format resep, mis. `R/ Parasetamol tab 500 mg No. X` dan `S 3 dd tab I p.c.` — sediaan otomatis disingkat (Tablet → tab, Kapsul → kaps, Sirup → syr, dst.), sama dengan resep yang tersimpan. |
| 6. Pembelajaran & Bukti | Poin pembelajaran dan unggahan berkas bukti. |

> Setting klinis menentukan jenis fasilitas: **Pelayanan Primer → FKTP**, selainnya **FKRTL** — inilah dasar kartu Pemenuhan Target Kasus.

#### Alur status kasus

<svg class="dg" viewBox="0 0 760 300" role="img" aria-label="Alur status kasus klinis dari draf hingga terverifikasi">
  <defs><marker id="ar-case" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <rect x="10" y="110" width="110" height="50" rx="10" class="dg-box-gray"/>
  <text x="65" y="140" class="dg-t dg-b" text-anchor="middle">Draf</text>
  <text x="65" y="180" class="dg-ts" text-anchor="middle">bisa dihapus</text>
  <rect x="260" y="110" width="170" height="50" rx="10" class="dg-box-amber"/>
  <text x="345" y="132" class="dg-t dg-b" text-anchor="middle">Menunggu Verifikasi</text>
  <text x="345" y="150" class="dg-ts" text-anchor="middle">antrean pembimbing</text>
  <rect x="570" y="20" width="180" height="50" rx="10" class="dg-box-green"/>
  <text x="660" y="42" class="dg-t dg-b" text-anchor="middle">Terverifikasi</text>
  <text x="660" y="60" class="dg-ts" text-anchor="middle">level entrustment + EPA</text>
  <rect x="570" y="120" width="180" height="50" rx="10" class="dg-box"/>
  <text x="660" y="142" class="dg-t dg-b" text-anchor="middle">Perlu Revisi</text>
  <text x="660" y="160" class="dg-ts" text-anchor="middle">bisa disunting lagi</text>
  <rect x="570" y="225" width="180" height="50" rx="10" class="dg-box-red"/>
  <text x="660" y="247" class="dg-t dg-b" text-anchor="middle">Ditolak</text>
  <text x="660" y="265" class="dg-ts" text-anchor="middle">final, bukan bukti</text>
  <line x1="120" y1="135" x2="258" y2="135" class="dg-arrow" marker-end="url(#ar-case)"/>
  <text x="189" y="127" class="dg-lbl" text-anchor="middle">Kirim untuk Verifikasi</text>
  <line x1="430" y1="122" x2="568" y2="50" class="dg-arrow" marker-end="url(#ar-case)"/>
  <text x="478" y="74" class="dg-lbl" text-anchor="middle">Setujui / Verifikasi</text>
  <line x1="430" y1="138" x2="568" y2="143" class="dg-arrow" marker-end="url(#ar-case)"/>
  <text x="499" y="131" class="dg-lbl" text-anchor="middle">Minta Revisi</text>
  <line x1="430" y1="152" x2="568" y2="245" class="dg-arrow" marker-end="url(#ar-case)"/>
  <text x="534" y="226" class="dg-lbl" text-anchor="middle">Tolak Kasus</text>
  <path d="M620,170 L620,195 L345,195 L345,162" fill="none" class="dg-arrow dg-dash" marker-end="url(#ar-case)"/>
  <text x="440" y="208" class="dg-lbl" text-anchor="middle">sunting → Kirim lagi</text>
  <path d="M570,35 L345,35 L345,108" fill="none" class="dg-arrow dg-dash" marker-end="url(#ar-case)"/>
  <text x="455" y="29" class="dg-lbl" text-anchor="middle">Batalkan Verifikasi (verifier asal / admin)</text>
  <text x="380" y="288" class="dg-lbl" text-anchor="middle">Setiap transisi tercatat di Riwayat Verifikasi; Komentar bisa ditambahkan kapan saja oleh pemilik &amp; pembimbing.</text>
</svg>

- **Draf** dan **Perlu Revisi** dapat Anda sunting; **Draf** dapat dihapus (refleksi yang menautkan draf itu tetap tersimpan, hanya tautannya dilepas).
- **Kirim untuk Verifikasi** mengirim kasus ke antrean pembimbing. Bila Anda menandai **Dosen/Preseptor Pembimbing**, kasus hanya masuk antrean dia, dia menerima notifikasi, dan **hanya dia** yang dapat memverifikasi, meminta revisi, atau menolaknya; tanpa tanda, kasus masuk antrean semua pembimbing. Tanda dapat diubah selama kasus masih Draf atau Perlu Revisi. Setelah dikirim, kasus tidak bisa disunting sampai diminta revisi.
- **Terverifikasi** membawa **level entrustment** (Diobservasi … Mengajari Junior), catatan pembimbing, kemungkinan **rekomendasi remediasi**, dan bila pembimbing memilih ranah EPA, **Peta EPA Anda ikut terisi**.
- **Ditolak** bersifat final (kasus tidak layak dijadikan bukti, mis. duplikat).
- **Riwayat Verifikasi** menampilkan setiap transisi beserta catatannya; **Kirim Komentar** memungkinkan diskusi dengan pembimbing tanpa mengubah status.

#### Identitas pasien, Privacy Mode, dan Break Glass

Selama **Contextual Privacy Mode** menyala (bawaan), identitas pasien tampil **tersamar untuk semua orang termasuk Anda sendiri**: nama menjadi inisial (`AF***`), No. RM menjadi `RM-****56`, sisanya `••••`. Satu-satunya pengecualian adalah pembimbing kasus Anda — preseptor rotasi pada tanggal kasus dan dosen yang memverifikasinya — yang melihat identitas langsung. Untuk membukanya sesaat, klik **Break Glass**, tulis alasan (minimal 10 karakter), dan identitas terbuka **30 menit** pada akun Anda. Setiap pembukaan tercatat permanen (siapa, kapan, alasan, alamat IP) dan dapat dilihat admin. Rincian ada di [Bab 7](#bab-7--privasi--keamanan-data-pasien).

#### Persetujuan pasien lewat QR

Pada kasus yang sudah tersimpan, klik **Terbitkan QR Persetujuan**. Pasien memindai QR (atau membuka tautannya) di ponselnya **tanpa login**, mencentang tiga butir — data kasus dipakai untuk pendidikan, foto klinis boleh disertakan, kasus boleh dipublikasikan setelah dianonimkan — lalu menulis nama dan relasi (pasien sendiri / wali). Jawaban tampil butir per butir di halaman kasus. Bila ada lampiran tetapi foto tidak disetujui, halaman memberi peringatan. **Terbitkan ulang** membatalkan lembar lama; **Cabut** menarik persetujuan.

#### Meminta asesmen dari kasus

Kasus berstatus *Menunggu Verifikasi* atau *Terverifikasi* dapat menjadi bahan asesmen:

- **Minta Mini-CEX** / **Minta DOPS** (isi nama prosedur): permintaan dikirim ke **preseptor rotasi** yang mencakup tanggal kasus (atau rotasi yang sedang berjalan). Konteks klinis tersalin dari kasus; statusnya *Diminta* sampai penilai mengisi rubrik. Permintaan yang belum disentuh penilai bisa Anda batalkan.
- **Inisiasi CBD / Long Case**: pilih event berbasis kasus yang tersedia untuk prodi/blok Anda. Kasus langsung tertaut dan berstatus *Dikumpulkan*; penguji terisi dari verifier kasus atau preseptor rotasi aktif.

### 4.4 Longitudinal Portfolio

**Ikhtisar → Longitudinal Portfolio** (`/portfolio`) merangkum seluruh Logbook Kegiatan: total kegiatan, jumlah **Klinis vs Non-Klinis**, **Tren 6 Bulan Terakhir**, jenis kegiatan terbanyak, dan tombol **Unduh CSV** untuk mengekspor seluruh kegiatan.

### 4.5 Rotasi Klinik dan Enrolment Tutorial

- **Rotasi Klinik** (`/clinical_rotations`): jadwal stase Anda — bagian/departemen, wahana, preseptor, periode, tanggal — dengan status **Akan Datang / Sedang Berlangsung / Selesai** yang dihitung dari tanggal. Rotasi hanya dibuat admin. Rotasi berjalan dipakai untuk: pengingat kasus di beranda, penilai bawaan DOPS/Mini-CEX, dan pencocokan event asesmen berdasarkan nama stase.
- **Enrolment Tutorial** (`/tutorial_enrollments`): padanan untuk tahap sarjana — blok/sistem, dosen tutor, periode, status Aktif/Selesai. Enrolment aktif menjadikan Anda "mahasiswa bimbingan" tutor di Dashboard Analitik dan menentukan event asesmen blok yang tampil.

### 4.6 Refleksi

**Perjalanan Belajar → Refleksi** (`/reflection_entries`) adalah jurnal tersendiri: tanggal, judul (opsional), isi bebas, dan tautan opsional ke satu **kegiatan** atau **kasus klinis**. Berbeda dari kolom "Refleksi" singkat di formulir kegiatan; gunakan ini untuk refleksi yang lebih panjang atau lintas kegiatan. Hanya Anda yang dapat membacanya.

Tautan hanya dapat dibuat ke kegiatan dan kasus **milik Anda sendiri**. Bila kegiatan atau draf kasus yang ditautkan kemudian dihapus, refleksi tetap tersimpan tanpa tautan.

### 4.7 Tugas Akhir

**Perjalanan Belajar → Tugas Akhir** (`/final_projects`):

1. **Daftarkan** tugas akhir: judul, deskripsi, dosen pembimbing (opsional), status **Proposal / Berjalan / Selesai**.
2. Tambahkan **milestone** bertanggal (checklist); tandai selesai atau buka lagi. Milestone yang lewat tanggal tanpa selesai ditandai **terlambat**.
3. **Skor ujian** diberikan penguji (0–100 + umpan balik per sesi; boleh lebih dari satu penguji). Rata-rata skor tampil di halaman proyek dan Anda menerima notifikasi setiap skor baru.

Proyek berstatus Proposal dapat Anda hapus; pembimbing dan admin juga dapat menyunting proyek Anda.

### 4.8 Evaluasi Akademik (nilai ujian)

**Asesmen & Evaluasi → Evaluasi Akademik** (`/nilai-ujian`) menampilkan seluruh nilai Anda **per tipe asesmen** beserta **tren persentase** dan daftar **asesmen menunggu** (terdaftar/dikumpulkan tetapi belum dinilai). Nilai masuk lewat tiga jalur — impor CSV oleh admin (CBT, OSCE, Progress Test, dsb.), Lembar Penguji (rubrik), atau inisiasi dari kasus (CBD/Long Case). Bila event mengizinkan percobaan berulang, nilai **tertinggi** yang menjadi wakil.

Empat belas tipe instrumen yang dikenal:

| Keluarga | Tipe | Cara nilai masuk |
|---|---|---|
| Ujian tulis | Ujian Tulis / CBT, Nilai Tutor, Ujian Tinjauan, TMEX, Progress Test | Impor CSV admin (termasuk berkas *CBT Exam Results* format Glide) |
| Ujian praktik | OSCE | Impor CSV admin (bisa per station, atau berkas *Penilaian OSCE* format Glide — 8 dimensi klinis) |
| Rubrik penguji | SOCA/MSP, Essay Gagasan, Festival Gagasan, Community Project, Refleksi Mahasiswa (dinilai), EBCR | Mahasiswa mengumpulkan → penguji menilai |
| Berbasis kasus | CBD, Long Case | Diinisiasi dari Kasus Klinis → penguji menilai |

Membuka satu nilai menampilkan **posisi Anda di kohort ujian** (persentil, rerata, P90) dan **radar per kategori dimensi**. Untuk CBT hasil impor, radar dikelompokkan per kategori tinjauan — Area Kompetensi, Sistem Organ, Sistem Kesehatan, Proses Klinis & Kognitif, Patomekanisme, dst. Untuk OSCE, halaman yang sama memuat **Rincian Station OSCE**: tiap station dengan kasus, penguji, delapan dimensi klinis (skala 0–3; nilai di bawah 2 ditandai merah), nilai checklist, *global rating* (Fail / Borderline / Good / Superior), serta umpan balik **Yang sudah baik** dan **Perlu ditingkatkan** dari penguji. Nilai OSCE Anda adalah rata-rata nilai checklist seluruh station pada sesi itu.

### 4.9 Workplace Assessment (DOPS & Mini-CEX)

**Asesmen & Evaluasi → Workplace Assessment** (`/asesmen`) menampilkan seluruh DOPS dan Mini-CEX Anda. Keduanya dinilai per dimensi pada skala **1–9** (1–3 di bawah harapan, 4–6 sesuai harapan, 7–9 melebihi harapan) beserta umpan balik naratif; halaman rincian menampilkan **radar chart** dimensi.

| | DOPS | Mini-CEX |
|---|---|---|
| Objek | satu prosedur (nama dari Master Keterampilan) | satu pertemuan pasien |
| Dimensi | 10: persetujuan tindakan, persiapan, analgesia/sedasi, kemampuan teknis, asepsis & keamanan pasien, meminta bantuan, evaluasi pasca tindakan, komunikasi, profesionalisme, penilaian global | 6: anamnesis, pemeriksaan fisik, clinical judgment, komunikasi, profesionalisme, organisasi & efisiensi + **penilaian global kualitatif** (Perlu Banyak Perbaikan … Melebihi Harapan) |
| Dimensi wajib | komunikasi, profesionalisme, penilaian global | komunikasi, profesionalisme |
| Konteks | setting klinis, kelompok usia, kompleksitas, durasi observasi & umpan balik, tautan rekaman video | sama |

<svg class="dg" viewBox="0 0 760 190" role="img" aria-label="Siklus status DOPS dan Mini-CEX: Diminta, Draf, Terkirim">
  <defs><marker id="ar-wba" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <rect x="10" y="30" width="180" height="56" rx="10" class="dg-box-amber"/>
  <text x="100" y="52" class="dg-t dg-b" text-anchor="middle">Diminta</text>
  <text x="100" y="70" class="dg-ts" text-anchor="middle">mahasiswa minta dari kasus</text>
  <rect x="290" y="30" width="180" height="56" rx="10" class="dg-box-gray"/>
  <text x="380" y="52" class="dg-t dg-b" text-anchor="middle">Draf</text>
  <text x="380" y="70" class="dg-ts" text-anchor="middle">penilai mulai mengisi rubrik</text>
  <rect x="570" y="30" width="180" height="56" rx="10" class="dg-box-green"/>
  <text x="660" y="52" class="dg-t dg-b" text-anchor="middle">Terkirim</text>
  <text x="660" y="70" class="dg-ts" text-anchor="middle">notifikasi; masuk radar &amp; jurnal</text>
  <line x1="190" y1="58" x2="288" y2="58" class="dg-arrow" marker-end="url(#ar-wba)"/>
  <text x="240" y="50" class="dg-lbl" text-anchor="middle">Simpan Draf</text>
  <line x1="470" y1="58" x2="568" y2="58" class="dg-arrow" marker-end="url(#ar-wba)"/>
  <text x="520" y="50" class="dg-lbl" text-anchor="middle">Kirim Evaluasi</text>
  <rect x="290" y="125" width="180" height="44" rx="10" class="dg-box"/>
  <text x="380" y="143" class="dg-t dg-b" text-anchor="middle">Penilai membuat langsung</text>
  <text x="380" y="159" class="dg-ts" text-anchor="middle">+ DOPS / + Mini-CEX di /asesmen</text>
  <line x1="380" y1="125" x2="380" y2="88" class="dg-arrow" marker-end="url(#ar-wba)"/>
  <path d="M470,147 L660,147 L660,88" fill="none" class="dg-arrow" marker-end="url(#ar-wba)"/>
  <text x="565" y="141" class="dg-lbl" text-anchor="middle">langsung kirim</text>
  <text x="100" y="125" class="dg-ts" text-anchor="middle">Mahasiswa boleh membatalkan</text>
  <text x="100" y="139" class="dg-ts" text-anchor="middle">selama masih "Diminta"</text>
</svg>

Notifikasi ke Anda **baru terkirim saat evaluasi berstatus Terkirim** — draf penilai tidak memicu notifikasi. Jadwal DOPS/Mini-CEX yang direncanakan admin/kaprodi tampil di **Agenda Mendatang** beranda saat jadwalnya tinggal 7 hari lagi.

### 4.10 Rubric-based Assessment (Asesmen Saya)

**Asesmen & Evaluasi → Rubric-based Assessment** (`/student/assessments`) memuat event **rubrik** dan **berbasis kasus** yang tersedia untuk Anda (prodi cocok, blok/stase cocok dengan enrolment/rotasi aktif, pengumpulan masih terbuka) dan seluruh percobaan Anda.

<svg class="dg" viewBox="0 0 760 200" role="img" aria-label="Alur asesmen rubrik dari pendaftaran hingga dinilai">
  <defs><marker id="ar-rub" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <rect x="10" y="30" width="150" height="56" rx="10" class="dg-box"/>
  <text x="85" y="52" class="dg-t dg-b" text-anchor="middle">Event Terbit</text>
  <text x="85" y="70" class="dg-ts" text-anchor="middle">admin; periode/prodi/blok</text>
  <rect x="200" y="30" width="150" height="56" rx="10" class="dg-box-gray"/>
  <text x="275" y="52" class="dg-t dg-b" text-anchor="middle">Terdaftar</text>
  <text x="275" y="70" class="dg-ts" text-anchor="middle">mahasiswa klik Daftar</text>
  <rect x="390" y="30" width="150" height="56" rx="10" class="dg-box-amber"/>
  <text x="465" y="52" class="dg-t dg-b" text-anchor="middle">Dikumpulkan</text>
  <text x="465" y="70" class="dg-ts" text-anchor="middle">dokumen + evaluasi diri</text>
  <rect x="580" y="30" width="170" height="56" rx="10" class="dg-box-green"/>
  <text x="665" y="52" class="dg-t dg-b" text-anchor="middle">Dinilai</text>
  <text x="665" y="70" class="dg-ts" text-anchor="middle">nilai + pertahankan/tingkatkan</text>
  <line x1="160" y1="58" x2="198" y2="58" class="dg-arrow" marker-end="url(#ar-rub)"/>
  <line x1="350" y1="58" x2="388" y2="58" class="dg-arrow" marker-end="url(#ar-rub)"/>
  <line x1="540" y1="58" x2="578" y2="58" class="dg-arrow" marker-end="url(#ar-rub)"/>
  <rect x="200" y="130" width="230" height="44" rx="10" class="dg-box"/>
  <text x="315" y="148" class="dg-t dg-b" text-anchor="middle">Inisiasi CBD / Long Case dari kasus</text>
  <text x="315" y="164" class="dg-ts" text-anchor="middle">kasus = dokumennya; langsung Dikumpulkan</text>
  <path d="M430,152 L465,152 L465,88" fill="none" class="dg-arrow" marker-end="url(#ar-rub)"/>
  <text x="600" y="120" class="dg-ts" text-anchor="middle">Setelah dinilai: notifikasi, masuk Evaluasi Akademik,</text>
  <text x="600" y="134" class="dg-ts" text-anchor="middle">Jurnal Umpan Balik, dan posisi terhadap kohort</text>
</svg>

1. Klik **Daftar** pada event yang tersedia (percobaan baru; bila event mengizinkan percobaan berulang, Anda dapat mendaftar lagi setelah dinilai).
2. Buka percobaan, **unggah dokumen** dan/atau tulis **evaluasi diri**, lalu **Kumpulkan**. Penguji yang ditunjuk menerima notifikasi; bila belum ada penguji, penguji mana pun dapat mengambilnya.
3. Setelah dinilai, halaman percobaan menampilkan nilai, umpan balik **pertahankan / tingkatkan**, rubrik yang diisi penguji (bila event memakai Assessment Form), dan **posisi Anda terhadap kohort** untuk event itu.

### 4.11 Jurnal Umpan Balik

**Asesmen & Evaluasi → Jurnal Umpan Balik** (`/student/feedback_journal`) menyatukan seluruh umpan balik tertulis — rubrik, CBD/Long Case, DOPS, Mini-CEX — dalam satu linimasa kronologis beserta skor dan nama penguji. Gunakan sebagai bahan refleksi.

### 4.12 Formulir evaluasi (Assessment Form)

**Assessment Form Builder** (`/assessment_form_templates`) — termasuk membuka dan mengisi formulir seperti **Evaluasi Dosen Tutor** dan **Evaluasi Blok** — hanya dapat diakses **kaprodi dan admin**; menunya tidak tampil bagi mahasiswa. Jawaban yang pernah Anda kirim, atau lembar yang menilai Anda, tetap dapat dibuka di `/assessment_form_submissions`; pada formulir **anonim**, identitas responden hanya terlihat oleh responden sendiri dan admin.

### 4.13 Peta Kompetensi (Analisis Capaian Pembelajaran)

**Kompetensi & Prestasi → Peta Kompetensi** (`/capaian-belajar`) adalah potret pribadi **satu periode akademik** (pilih dari dropdown). Sengaja tidak ada grafik tren antar-periode, karena jenis dan bobot asesmen berganti tiap periode sehingga tren rata-ratanya menyesatkan.

Isinya:

- **Radar DOPS & Mini-CEX** periode itu (rata-rata per dimensi) beserta daftar evaluasinya per rotasi.
- **Target milestone** per ranah kompetensi yang ditetapkan admin, dengan lencana **Tercapai / Di Bawah Target** — dibandingkan dengan rata-rata keseluruhan DOPS+Mini-CEX Anda (proksi umum, dilabeli demikian).
- **Nilai ujian** periode itu (dari Assessment Events).
- **Capaian per ranah kompetensi** dari mata uji/station yang dipetakan admin ke ranah.
- **Nilai Learning Unit** (blok/modul) dari Assessment Matrix: rata-rata terbobot komponen yang **sudah dinilai**, dilabeli "dari X% bobot".
- **Posisi terhadap Kohort**: pita P10–P90, median, dan penanda posisi Anda, **per tipe asesmen dalam satu periode**; hanya tampil bila kohort ≥ 3 mahasiswa (agar nilai perorangan tak bisa diterka).

### 4.14 Peta EPA & Tingkat Entrustment

**Kompetensi & Prestasi → Peta EPA & Entrustment** (`/dashboard/entrustment`) menampilkan tingkat entrustment Anda **1–5** untuk setiap ranah tingkat atas Kerangka Kompetensi, plus riwayat keputusannya:

| Level | Makna |
|---|---|
| 1 | Hanya mengamati, tidak boleh terlibat |
| 2 | Boleh terlibat dengan supervisi penuh |
| 3 | Bisa mandiri dengan supervisi tidak langsung |
| 4 | Mandiri penuh |
| 5 | Mampu mengajarkan dan mensupervisi junior |

Keputusan baru **menggantikan** yang lama (riwayat tetap tersimpan). Sumbernya dua: otomatis saat pembimbing memverifikasi kasus dan memilih ranah EPA (level entrustment kasus dipetakan ke 1–5), atau manual oleh pembimbing yang berelasi dengan Anda. Bila verifikasi kasus dibatalkan, level yang lahir dari kasus itu dicabut dan keputusan sebelumnya dipulihkan.

---

## Bab 5 — Panduan Pembimbing (Dosen, Preseptor, Kaprodi)

### 5.1 Beranda pembimbing

Beranda dosen, preseptor, kaprodi, dan admin mengikuti pola beranda pembimbing jejak.pro:

- **Ringkasan Hari Ini** — kartu angka yang hanya "menyala" bila ada pekerjaan; kartu bernilai nol menampilkan *✓ Beres*:
  - **Kasus Perlu Diverifikasi** dan **Kegiatan Perlu Divalidasi** — antrean yang sama dengan menu Validasi Kasus Klinis / Validasi Kegiatan (tidak tampil bagi kaprodi tanpa peran pengajar).
  - **Perlu Dinilai** — DOPS/Mini-CEX yang diminta mahasiswa atau masih draf dengan Anda sebagai penilai, ditambah percobaan asesmen (rubrik, CBD, Long Case) yang sudah dikumpulkan dan ditugaskan kepada Anda.
  - **Mahasiswa Perlu Perhatian** — lihat di bawah.
  - **Jadwal Evaluasi Prodi** (preseptor, atau siapa pun yang punya jadwal) — jadwal DOPS/Mini-CEX sampai akhir bulan yang belum ditunaikan.
  - **Agenda 7 Hari**.
- **Perlu Tindakan Anda** — panel untuk tiap antrean di atas (kasus terlama menunggu tampil paling atas; tombol *Isi Penilaian* langsung ke lembarnya). Bila semuanya kosong, tampil keadaan **Semua beres**.
- **Mahasiswa Perlu Perhatian Khusus** — mahasiswa bimbingan (kaprodi: ditambah seluruh mahasiswa prodinya) yang dalam **30 hari terakhir** punya kasus terverifikasi dengan **rekomendasi remediasi**, atau rata-rata DOPS/Mini-CEX **di bawah 4**; bagi preseptor juga mahasiswa rotasinya yang **7 hari** tidak mencatat kasus.
- **Mahasiswa Bimbingan Anda** — dikelompokkan per peran: **Modul Preseptor Klinis** (rotasi yang sedang berjalan), **Modul Tutor** (blok aktif), dan **Pembimbing Tugas Akhir** (progres milestone). Tiap mahasiswa bertaut ke Dasbor Mahasiswa (hanya-baca).
- Kolom samping: **Agenda Mendatang**, **Ringkasan Bimbingan** (jumlah mahasiswa per peran dan rekam umpan balik naratif Anda), serta **Akses Cepat** (admin mendapat tautan Jadwal DOPS & Mini-CEX dan Pengguna).

Jadwal DOPS/Mini-CEX di panel *Jadwal Evaluasi Bulan Ini* hilang sendiri begitu Anda mengirim penilaian sejenis untuk mahasiswa tersebut sejak awal bulan jadwalnya — tidak perlu menunggu admin menandainya Selesai.

### 5.2 Validasi Kasus Klinis

**Coaching Center → Validasi Kasus Klinis** (`/clinical_cases?scope=to_verify`) adalah antrean kasus berstatus *Menunggu Verifikasi* yang menandai Anda sebagai pembimbing, ditambah kasus tanpa tanda pembimbing dari mahasiswa mana pun. Kasus yang menandai pengajar lain tidak masuk antrean Anda dan tidak dapat Anda verifikasi. Buka kasus, baca seluruh langkah, lalu pilih salah satu:

| Aksi | Kapan | Efek |
|---|---|---|
| **Setujui / Verifikasi** | kasus layak | Pilih **level entrustment** (Diobservasi, Dibantu, Supervisi Langsung, Supervisi Tidak Langsung, Mandiri, Mengajari Junior), tulis catatan, centang **Rekomendasi remediasi** bila perlu, dan centang **ranah EPA** yang ingin ditulis ke Peta EPA mahasiswa. |
| **Minta Revisi** | ada yang perlu diperbaiki (catatan wajib) | Kasus kembali dapat disunting mahasiswa dan dikirim ulang. |
| **Tolak Kasus** | kasus tidak layak menjadi bukti (alasan wajib) | Final. |
| **Batalkan Verifikasi** | Anda (verifier asal) atau admin salah menyetujui (alasan wajib) | Kasus kembali ke antrean; level EPA dari verifikasi itu dicabut. |
| **Kirim Komentar** | diskusi tanpa mengubah status | Pemilik/verifier menerima notifikasi. |

Kasus yang sudah Anda verifikasi, minta revisi, atau tolak keluar dari antrean, tetapi tetap bisa dibuka ulang lewat tab **Riwayat Verifikasi** (`/clinical_cases?scope=reviewed`) di halaman yang sama.

Anda tidak dapat memverifikasi kasus milik akun sendiri. Bila Anda pembimbing kasus itu — yang ditandai mahasiswa, preseptor rotasi mahasiswa pada tanggal kasus, atau dosen yang sudah memverifikasi, meminta revisi, atau menolaknya — identitas pasien tampil langsung. Pengajar lain melihatnya tersamar oleh Privacy Mode; gunakan Break Glass hanya bila benar-benar perlu — semua pembukaan Break Glass diaudit.

### 5.3 Validasi Kegiatan

**Coaching Center → Validasi Kegiatan** (`/activity_logs?scope=to_verify`) memuat kegiatan logbook yang belum diverifikasi dari semua mahasiswa, dengan filter domain dan kompetensi. Buka kegiatan, periksa bukti/tautan, klik **Verifikasi**. Tidak ada aksi "tolak" — kegiatan yang tidak layak cukup dibiarkan tanpa verifikasi dan dibicarakan dengan mahasiswa.

### 5.4 Menilai DOPS dan Mini-CEX

Dari **Workplace Assessment** (`/asesmen`) klik **+ DOPS** atau **+ Mini-CEX**, atau buka permintaan mahasiswa dari kartu *Evaluasi Belum Dikirim*. Panel **Menunggu Diselesaikan** memuat permintaan dan draf Anda.

1. Pilih mahasiswa dan rotasi klinik. Daftar rotasi bertuliskan *stase — nama mahasiswa*; pilih rotasi **milik mahasiswa yang dinilai** — rotasi mahasiswa lain ditolak, karena nilainya akan salah atribusi dan tidak terhitung di Dashboard Analitik. Pada permintaan dari kasus, keduanya sudah terisi beserta konteks klinis.
2. Isi tanggal, nama prosedur (DOPS, dengan autocomplete Master Keterampilan) atau deskripsi kasus (Mini-CEX), setting klinis, kelompok usia, kompleksitas, durasi observasi & umpan balik, tautan video (opsional).
3. Beri skor tiap dimensi lewat **kartu radio 1–9** berpita warna (merah 1–3, kuning 4–6, hijau 7–9). Dimensi yang tidak diamati boleh **N/A**, kecuali dimensi wajib (DOPS: komunikasi, profesionalisme, penilaian global; Mini-CEX: komunikasi, profesionalisme). Mini-CEX juga meminta **penilaian global** kualitatif.
4. Tulis umpan balik naratif, lalu **Simpan Draf** (lanjutkan nanti) atau **Kirim Evaluasi** (mahasiswa diberi tahu; skor masuk radar, capaian, dan jurnal).

Hanya penilai asal atau admin yang dapat menyunting/menghapus evaluasi.

### 5.5 Lembar Penguji (rubrik, CBD, Long Case)

**Asesmen & Evaluasi → Rubric-based Assessment** bagi pembimbing membuka **Lembar Penguji** (`/examiner_evaluations`): antrean percobaan yang **ditugaskan kepada Anda** (belum dinilai di atas) dan percobaan **belum bertugas** yang sudah dikumpulkan — siapa pun pembimbing boleh mengambilnya.

Buka percobaan: baca dokumen/evaluasi diri mahasiswa (atau kasus klinis yang ditautkan untuk CBD/Long Case), lalu:

- bila event memakai **rubrik Assessment Form**, isi rubriknya di sini — nilai dihitung otomatis dari jawaban berbobot. Pertanyaan wajib harus dijawab, dan minimal satu pertanyaan bernilai (skala, skor, atau rubrik berjenjang) harus terisi. Mengisi ulang rubrik **menggantikan** lembar sebelumnya; bila isian ulang ditolak, lembar dan nilai lama tetap berlaku;
- bila tidak, ketik **nilai** (≤ nilai maksimum event);
- tulis umpan balik **Pertahankan** dan **Tingkatkan**, lalu simpan.

Mahasiswa menerima notifikasi; nilai tampil di Evaluasi Akademik, Jurnal Umpan Balik, dan kurva kohort.

### 5.6 Tugas Akhir: membimbing dan menguji

Semua pembimbing dapat melihat **seluruh** tugas akhir (`/final_projects`) karena siapa pun berpotensi menjadi penguji. Pembimbing yang ditunjuk mahasiswa dapat menyunting proyek dan milestone-nya. Untuk menguji, buka proyek → **Beri Skor**: tanggal sesi, skor 0–100, umpan balik. Mahasiswa diberi tahu; rata-rata seluruh penguji tampil di proyek.

### 5.7 Memutuskan tingkat EPA

Buka **Peta EPA & Entrustment** lalu pilih mahasiswa (`/dashboard/entrustment?student_id=…`, atau dari tautan pada Dashboard Analitik / profil mahasiswa). Bila Anda **berelasi** dengan mahasiswa itu (tutor, preseptor rotasi, pembimbing TA, atau pernah memverifikasi kasus/menilai DOPS-Mini-CEX-nya), formulir keputusan tampil: pilih ranah, level 1–5, dan **justifikasi** (minimal 10 karakter). Kaprodi dapat membuka peta mahasiswa prodinya tetapi tidak memutuskan.

### 5.8 Dashboard Analitik

**Coaching Center → Dashboard Analitik** (`/analitik`) adalah satu halaman dengan bagian yang tampil sesuai peran yang Anda miliki (bisa lebih dari satu sekaligus), dan **filter periode akademik** di kepala halaman yang menyaring ketiganya:

| Bagian | Untuk | Siapa yang tampil |
|---|---|---|
| **Mahasiswa Bimbingan** | dosen, admin | Mahasiswa yang tugas akhirnya Anda bimbing, pernah Anda nilai DOPS/Mini-CEX, atau tutee aktif Anda |
| **Mahasiswa di Wahana Anda** | preseptor, admin | Mahasiswa pada rotasi yang menunjuk Anda sebagai preseptor, dengan hitungan kegiatan & DOPS/Mini-CEX selama rentang rotasi |
| **Program Studi** | kaprodi, admin | Seluruh mahasiswa satu prodi (kaprodi terkunci ke prodinya; admin memilih prodi), plus **radar kohort** DOPS+Mini-CEX |

Tiap baris memuat jumlah kegiatan pada periode terpilih (kolom **Kegiatan Periode Ini**; bila belum ada periode akademik sama sekali, **Kegiatan Bulan Ini**), rata-rata DOPS, rata-rata Mini-CEX, rasio kasus terverifikasi, dengan **lencana warna** (hijau/kuning/merah) dan diurutkan **dari yang paling berisiko** (rata-rata terendah di atas; mahasiswa tanpa data diletakkan di akhir). Hanya evaluasi **Terkirim** yang dihitung.

### 5.9 Daftar Mahasiswa

**Coaching Center → Daftar Mahasiswa** membuka halaman Pencarian (`/cari`) — cari nama/email, lalu klik kartu untuk membuka profil pengguna dan dari sana ke Peta EPA-nya.

### 5.10 Khusus kaprodi

- **Relabel Prodi Mahasiswa** (`/admin/student_relabel/new`): unggah CSV `email,npm,angkatan` → pratinjau per baris → terapkan. Kaprodi dapat **Pindah** mahasiswa prodinya sendiri atau **Label ke prodi saya** (mengklaim mahasiswa dari prodi mana pun ke prodi Anda). Rincian format di [Relabel Prodi Mahasiswa](#relabel-prodi-mahasiswa).
- **Prodi binaan** akun Anda menentukan cakupan bagian *Program Studi* di Dashboard Analitik dan mahasiswa yang boleh Anda pindahkan di Relabel. Prodi ini ditetapkan admin (**Konfigurasi → Pengguna → Sunting**) dan tidak dapat diubah dari Sunting Profil. Bila belum diisi, Relabel Prodi menolak dengan pesan *akun kaprodi belum terhubung ke Program Studi*.
- **Jadwal DOPS & Mini-CEX** (`/admin/evaluation_schedules`) dan **Learning Unit & Matrix** (`/admin/learning_units`) juga terbuka untuk kaprodi meski tidak ada di sidebar kaprodi — buka lewat alamatnya. Lihat [Bab 6](#bab-6--panduan-admin-konfigurasi).

---

## Bab 6 — Panduan Admin (Konfigurasi)

Urutan penyiapan instalasi baru yang disarankan: **Tahun/Periode Akademik → Program Studi → Pengguna → Kerangka Kompetensi → Target Kasus & Domain Kegiatan → Rotasi/Enrolment → Assessment Events**. Sisanya bisa menyusul.

### 6.1 Tahun/Periode Akademik

`/academic_periods` — nama, tanggal mulai, tanggal selesai. Periode dipakai oleh rotasi, enrolment tutorial, event asesmen, Learning Unit, target kasus, milestone kompetensi, dan filter Dashboard Analitik / Peta Kompetensi. Semester pada Logbook Kegiatan terisi otomatis hanya bila **tepat satu** periode mencakup tanggal kegiatan — hindari periode yang tumpang-tindih.

Periode yang sudah dipakai rotasi klinik, enrolment tutorial, Assessment Event, target milestone kompetensi, Learning Unit, atau target kasus **tidak dapat dihapus**; pesan penolakan menyebut jumlah pemakaiannya (mis. *3 rotasi klinis dan 1 assessment event*). Rotasi dan data lain tidak ikut terhapus. Kegiatan logbook yang hanya mencantumkan semester itu tidak menghalangi — tautan semesternya saja yang dilepas. Periode yang keliru dibuat dan belum dipakai dapat dihapus seperti biasa.

### 6.2 Program Studi

`/study_programs` — nama, **kode** (huruf kecil, unik; bawaan `pssk` dan `pspd`), **jenjang** (sarjana/profesi). Kode prodi dipakai importer CSV pengguna dan paket migrasi.

### 6.3 Pengguna & impor CSV

`/admin/users` — daftar berpenyaring (nama/email, peran, prodi). **Sunting** mengubah nama, prodi, dan peran (minimal satu peran; peran aktif ikut disesuaikan bila dicabut) — untuk akun kaprodi, prodi di sini adalah **prodi binaan** yang membatasi hak aksesnya dan hanya dapat diubah admin; **Reset ke Bawaan** mengembalikan kata sandi ke `password123`, dan **Konfirmasi Sekarang** mengaktifkan akun yang tersangkut konfirmasi email.

**Impor CSV** (`/admin/users/import`) — header baris pertama, urutan kolom bebas, pemisah koma atau titik koma:

~~~csv
email,nama,peran,prodi
ani@kampus.ac.id,Ani Lestari,mahasiswa,pspd
budi@kampus.ac.id,Budi Santoso,dosen+preseptor,
~~~

- `peran`: kode dipisah `+` atau `;` (mahasiswa, dosen, preseptor, kaprodi, admin); kosong → mahasiswa.
- `prodi`: kode atau nama prodi; kosong → tidak diubah.
- Akun baru: kata sandi bawaan, langsung terkonfirmasi. Akun lama: hanya nama/peran/prodi yang diperbarui, kata sandi tidak disentuh. Setiap baris gagal dilaporkan dengan nomor barisnya.

### 6.4 Relabel Prodi Mahasiswa

`/admin/student_relabel/new` — memindahkan mahasiswa antar-prodi secara massal (mis. mahasiswa PSSK yang lanjut ke PSPD) sekaligus memperbarui NPM dan angkatan.

~~~csv
email,npm,angkatan
ani@kampus.ac.id,2301234567,2023
1901111111,2301234568,
~~~

- `email`: email akun **atau NPM lama**; `npm`: NPM baru (kosong = tetap); `angkatan`: kosong = angkatan bawaan formulir, atau tidak diubah.
- Alur **dua tahap**: **Pratinjau** menampilkan status tiap baris ("siap" atau alasan dilewati), lalu **Terapkan** menyimpan seluruh baris siap dalam **satu transaksi**.
- Baris dilewati (tidak menggagalkan batch) bila: akun tidak ditemukan, NPM lama cocok >1 akun, bukan peran Mahasiswa, muncul dua kali, angkatan tak terbaca, di luar prodi kaprodi, NPM baru dobel, atau tidak ada perubahan.
- Tidak ada mode "Tandai Lulus" — JEJAK Essential tidak mengelola status alumni.

### 6.5 Assessment Events dan impor nilai

`/admin/assessment_events` — satu event = satu ujian/penilaian pada satu **periode**, opsional dibatasi **prodi** dan **blok/stase** (dicocokkan dengan nama blok enrolment tutorial / nama stase rotasi mahasiswa). Isian: nama, **tipe** (14 tipe, lihat [4.8](#evaluasi-akademik-nilai-ujian)), tanggal ujian, **nilai maksimum**, **status** (Draf → Terbit → Ditutup; hanya Terbit yang tampil ke mahasiswa), batas waktu pengumpulan, **izinkan percobaan berulang**, dan untuk keluarga rubrik: **Assessment Form Template** sebagai rubrik terstruktur.

Halaman event memuat:

- **Daftarkan mahasiswa** secara manual (dengan penguji dan jadwal opsional).
- **Hapus event** hanya untuk event yang belum punya nilai — event bernilai cukup diubah statusnya menjadi **Ditutup**. Percobaan yang belum dinilai, dimensi, dan komponen event itu pada Assessment Matrix Learning Unit ikut terhapus.
- **Dimensi** (mata uji CBT / station OSCE): nama, kode, bobot, nilai maks, dan **pemetaan ke ranah kompetensi** (tombol petakan massal). Event berdimensi menghitung nilai total dari rata-rata terbobot dimensi yang terisi; pemetaan inilah sumber "Capaian per ranah" di Peta Kompetensi.
- **Impor nilai** (ujian tulis/praktik):

<svg class="dg" viewBox="0 0 760 130" role="img" aria-label="Impor nilai CSV tiga langkah">
  <defs><marker id="ar-imp" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <rect x="10" y="20" width="160" height="70" rx="10" class="dg-box"/>
  <text x="90" y="44" class="dg-t dg-b" text-anchor="middle">0. Unduh templat</text>
  <text x="90" y="62" class="dg-ts" text-anchor="middle">berisi email mahasiswa prodi</text>
  <text x="90" y="76" class="dg-ts" text-anchor="middle">+ kolom nilai kosong</text>
  <rect x="205" y="20" width="160" height="70" rx="10" class="dg-box"/>
  <text x="285" y="44" class="dg-t dg-b" text-anchor="middle">1. Unggah CSV</text>
  <text x="285" y="62" class="dg-ts" text-anchor="middle">koma / titik koma, BOM</text>
  <text x="285" y="76" class="dg-ts" text-anchor="middle">&amp; desimal koma aman</text>
  <rect x="400" y="20" width="160" height="70" rx="10" class="dg-box-amber"/>
  <text x="480" y="44" class="dg-t dg-b" text-anchor="middle">2. Petakan kolom</text>
  <text x="480" y="62" class="dg-ts" text-anchor="middle">email, skor, nilai maks,</text>
  <text x="480" y="76" class="dg-ts" text-anchor="middle">percobaan, tanggal, dimensi</text>
  <rect x="595" y="20" width="155" height="70" rx="10" class="dg-box-green"/>
  <text x="672" y="44" class="dg-t dg-b" text-anchor="middle">3. Jalankan</text>
  <text x="672" y="62" class="dg-ts" text-anchor="middle">laporan: dibuat, diperbarui,</text>
  <text x="672" y="76" class="dg-ts" text-anchor="middle">email tak dikenal</text>
  <line x1="170" y1="55" x2="203" y2="55" class="dg-arrow" marker-end="url(#ar-imp)"/>
  <line x1="365" y1="55" x2="398" y2="55" class="dg-arrow" marker-end="url(#ar-imp)"/>
  <line x1="560" y1="55" x2="593" y2="55" class="dg-arrow" marker-end="url(#ar-imp)"/>
  <text x="380" y="118" class="dg-lbl" text-anchor="middle">Pemetaan ditebak otomatis dari nama header; email yang tidak dikenal dilaporkan, tidak dibuat akun baru.</text>
</svg>

Templat CSV dari tombol **Unduh templat** memuat kolom `email,nama_mahasiswa,npm,skor[,percobaan],tanggal[,<nama dimensi>…]` — kolom nama & NPM hanya penanda, baris yang nilainya dibiarkan kosong dilewati, dan `tanggal` (bawaan = tanggal ujian event) bisa diubah per baris untuk ujian susulan. Event tanpa percobaan berulang **menimpa** percobaan 1; event berulang menambah percobaan baru. Laporan impor menyebut jumlah nilai baru, diperbarui, nilai per dimensi, email tak dikenal, dan baris gagal; baris yang bernilai tetapi kolom emailnya kosong dilaporkan sebagai *(baris N tanpa email)*.

#### Impor CSV CBT & OSCE (format Glide)

**Konfigurasi → Impor CSV CBT & OSCE** (`/admin/glide_syncs`, padanan `/admin/glide_syncs/csv_import` jejak.pro) menerima **berkas .csv** hasil ekspor tabel Glide — tanpa koneksi API Glide. Berkas yang sama juga diterima jejak.pro, jadi data dapat dipindahkan bolak-balik. Tombol **+ Upload CSV** membuka formulir: pilih tipe data, unggah berkas (hingga 50 MB, pemisah koma/titik koma), lalu **Mulai Impor**. Tiap tipe punya tombol **Unduh templat CSV** berisi header persis ekspor Glide.

| Tipe | Berkas | Isi |
|---|---|---|
| **CBT Exam Results** | `data_cbt_exams_glide.csv` | ekspor hasil ujian per sesi: `Nomor Ujian`, `Nama Peserta`, `email`, `Tanggal` (mis. *9 September 2026*), `Sesi`, `Jumlah Benar`, `Jumlah Raw Nilai`, `Nilai Akhir` (skala 100), lalu **satu kolom per dimensi** berprefiks kelompok — `[AK]` Area Kompetensi, `[ST]` Sistem Organ, `[TK]`/`[TI]` Tingkat Kemampuan, `[KAT]` kategori soal. Format Glide lama (`email`, `exam_code`, `exam_title`, `exam_type`, `total_score`, `held_at`, kolom dimensi tanpa prefiks) tetap diterima |
| **OSCE** | `data_osce_glide.csv` | satu baris = satu station: `$rowID`, `emailYangDiuji`, `emailPenguji`, `tanggalEntry`, `station`, `kasus`, `IDSoal`, delapan dimensi klinis skala 0–3 (`Anamnesis`, `PemeriksaanFisik`, `InterpretasiData`, `PenegakanDiagnosis`, `TatalaksanaNonFarmakoterapi`, `TatalaksanaFarmakoterapi`, `KomunikasiDanEdukasiPasien`, `PerilakuProfesional`), `globalRating`, `halBaik`, `perluDitingkatkan`, `refleksi` |

Cara data masuk:

- **CBT** — satu `exam_code` = satu Assessment Event (dibuat otomatis bila belum ada; tipe *Progress Test* bila `exam_type` = progress_test, selain itu CBT Sumatif/Formatif). Periode akademik = periode yang memuat tanggal ujian. Setiap kolom selain kolom identitas & keterangan (`Nama Peserta`, `Sesi`, `Jumlah Benar`, …, serta kolom yang seluruh isinya teks) menjadi **dimensi** yang dikelompokkan ke kategori tinjauan — menurut prefiksnya (`[AK] Komunikasi efektif` → Area Kompetensi, nama dimensi "Komunikasi efektif"), atau ditebak dari namanya; kolom `[KAT]` dipilah ke Siklus Kehidupan, Setting Klinis, Aspek, Proses Klinis, Patomekanisme, dan sisanya **Kategori Soal**. Kolom yang bernilai **0 untuk semua peserta** dianggap kelompok tanpa soal di ujian itu dan tidak dijadikan dimensi (daftarnya tampil di ringkasan impor), supaya radar dan Peta Kompetensi tidak terisi nol palsu. Dimensi yang namanya sama persis dengan ranah kompetensi (mis. "Komunikasi efektif") langsung dipetakan. Opsi khusus CBT: **Judul ujian** dan **Tanggal ujian** menimpa isi berkas; berkas tanpa `exam_code` (termasuk ekspor per sesi) memakai kode dari judul (atau nama berkas) + tanggal — isi Judul ujian agar nama event rapi.
- **OSCE** — bawaan: **satu event per hari ujian** ("OSCE 20 Oktober 2025", tanggal entri dalam WIB), seperti rekap Sesi OSCE jejak.pro; atau pilih **Event tujuan** bila seluruh berkas adalah satu ujian. Delapan dimensi klinis dibuat sebagai dimensi event (maks 3). Nilai tiap mahasiswa = rata-rata nilai checklist station-nya; nilai per dimensi = rata-rata station yang menilainya. Halaman event mendapat tab **Station OSCE** berisi rincian per station, rata-rata dimensi, dan sebaran global rating.
- Opsi bersama: **Program studi** dan **Periode akademik** untuk event yang baru dibuat.

Aturan pengaman:

- **Idempoten** — OSCE berdasarkan `$rowID` (baris tanpa `$rowID`: mahasiswa + soal + penguji + hari), CBT berdasarkan mahasiswa + `exam_code`. Mengunggah ulang berkas yang sama tidak menggandakan nilai; nilai yang sudah ada **tidak ditimpa**.
- Email yang belum terdaftar sebagai **mahasiswa** dilewati (tidak dibuat akun). Nilai di luar skala, tanggal tak terbaca atau tak wajar (mis. tahun 2116), dan sel nilai bukan angka dilaporkan per baris.
- Mahasiswa yang sudah punya nilai OSCE dari sumber lain (input manual / impor generik) pada event tujuan tidak ditimpa station Glide.
- Setelah impor, halaman **ringkasan** menampilkan baris dibaca, nilai/station masuk, alasan dilewati, contoh galat, dan event yang terisi. **Rollback** di halaman itu menghapus semua yang dibuat unggahan tersebut (station, peserta, event baru yang kosong) dan mengembalikan peserta yang sebelumnya terdaftar ke status *Terdaftar*. Untuk mengoreksi nilai: rollback, perbaiki berkas, lalu unggah ulang.

#### Kelola Ujian CBT

**Konfigurasi → Kelola Ujian CBT** (`/admin/cbt_exams`) mendaftar seluruh event CBT & Progress Test beserta kode ujian, tipe, jumlah peserta, tanggal, dan progres pemetaan dimensi. Klik **judul** atau **tanggal** untuk menyunting di tempat; mengoreksi tanggal ikut memindahkan tanggal nilai hasil impor sehingga grafik tren tetap benar. **Kelola Pemetaan** membuka tab Dimensi event untuk memetakan dimensi ke ranah kompetensi. Berbeda dari jejak.pro, ujian yang sudah bernilai **tidak dapat dihapus** dari sini — batalkan lewat rollback impor, atau ubah status event menjadi Ditutup.

### 6.6 Jadwal DOPS & Mini-CEX

`/admin/evaluation_schedules` (admin & kaprodi) — rencana penilaian: jenis (DOPS/Mini-CEX), mahasiswa, penilai, rotasi, waktu, status **Terjadwal / Selesai / Dibatalkan**. Jadwal tampil di beranda mahasiswa dan penilai; penilaian tetap dicatat lewat formulir DOPS/Mini-CEX, lalu tandai jadwalnya Selesai.

### 6.7 Kerangka Kompetensi

`/competency_frameworks` — pohon dua tingkat: **ranah/domain** (tingkat atas) dan **sub-kompetensi**. Bawaan: *Standar Kompetensi Dokter Indonesia (Ringkas)* dengan 7 area. Semua pengguna dapat melihatnya; hanya admin yang menambah/menghapus butir (form inline di halaman detail). Ranah tingkat atas berfungsi sebagai **EPA** di Peta EPA. Dari baris ranah, admin juga menetapkan **target milestone** (skor 1–9 per periode, lewat formulir **Set Target**) yang tampil di Peta Kompetensi mahasiswa.

Aturan menghapus butir:

- Sub-kompetensinya ikut terhapus, begitu pula **tag kompetensi pada kegiatan**, **pemetaan blueprint**, dan **target milestone**-nya.
- **Pemetaan dimensi ujian dan pertanyaan rubrik dilepas** — dimensi dan pertanyaannya tetap ada, hanya tanpa ranah.
- Butir yang (atau yang sub-kompetensinya) sudah dipakai **keputusan EPA** mahasiswa **tidak dapat dihapus**, karena keputusan itu adalah nilai mahasiswa. Aturan yang sama berlaku saat menghapus seluruh kerangka.

### 6.8 Blueprint Asesmen

`/assessment_blueprints` — nama, deskripsi, daftar **capaian pembelajaran**, dan pemetaan **kompetensi → bobot** (ditambahkan satu per satu dari formulir di halaman detail, total dianjurkan 100%; radar chart bobot di halaman detail). Blueprint dapat dirujuk oleh Learning Unit; menghapus blueprint tidak menghapus Learning Unit yang merujuknya — rujukannya saja yang dilepas.

### 6.9 Learning Unit & Matrix

`/admin/learning_units` (admin & kaprodi) — blok/modul per prodi (opsional per periode, SKS, blueprint). **Assessment Matrix**: tambahkan komponen berupa Assessment Event beserta bobot; total 100% ditandai hijau. Halaman unit menampilkan **rekap nilai per mahasiswa** — rata-rata terbobot dari komponen yang sudah dinilai (bobot tanpa nilai tidak menjadi penyebut).

### 6.10 Target Kasus Logbook

`/admin/logbook_case_targets` — target jumlah kasus **terverifikasi** per prodi × jenis fasilitas (**FKTP** = Pelayanan Primer, **FKRTL** = rumah sakit), opsional per periode. Target periode berjalan diutamakan atas target umum prodi. Tampil sebagai kartu Pemenuhan Target Kasus di halaman Kasus Klinis mahasiswa.

### 6.11 Domain Kegiatan Akademik

`/admin/academic_activity_domains` — satu halaman pohon Domain → Subdomain/Kategori → Bentuk Kegiatan: tambah, sunting, geser urutan (▲▼), aktif/nonaktif, hapus, dengan jumlah pemakaian per simpul. Simpul yang sudah dipakai kegiatan **tidak bisa dihapus** — nonaktifkan saja: hilang dari formulir, kegiatan lama tetap utuh. Centang **Kegiatan klinis** pada domain yang harus dihitung Klinis di Portfolio. Isi bawaan (Praktek, Belajar Mengajar, Prestasi Kemahasiswaan, dll.) disalin saat instalasi hanya bila tabel masih kosong.

### 6.12 Master Diagnosis, Keterampilan, Obat

- **Master Diagnosis** (`/admin/diagnosis_definitions`): nama, kode ICD-10, level SKDI, sistem. Menjadi autocomplete diagnosis di wizard kasus dan sumber lencana ICD-10/SKDI. Bawaan 42 diagnosis.
- **Master Keterampilan** (`/admin/skill_definitions`): nama prosedur untuk autocomplete DOPS. Bawaan 25 keterampilan.
- **Master Obat** (`/admin/medication_definitions`): daftar obat untuk latihan resep di wizard kasus.

Ketiganya mendukung **impor CSV** (header alias ID/EN dikenali).

### 6.13 Assessment Form Builder (templat formulir)

`/assessment_form_templates` — hanya untuk **kaprodi dan admin** (keduanya mengelola penuh; pengguna lain ditolak dan tidak melihat menunya). Kaprodi/admin membuat templat: nama, deskripsi, **aktif**, **anonim**, **wajib pilih subjek** (orang yang dinilai). Tambahkan pertanyaan: label, jenis (Skala 1–5, Skor Angka 0–maks, Rubrik Berjenjang dengan deskriptor per tingkat, Pilihan Ganda, Ya/Tidak, Teks Singkat, Teks Panjang), wajib/opsional, **bobot**, dan **pemetaan ke ranah kompetensi**; urutan diatur dengan ▲▼. Jenis pertanyaan terkunci setelah ada jawaban. Templat dipakai dua cara: diisi langsung oleh kaprodi/admin lewat **Isi Formulir**, atau ditunjuk sebagai **rubrik** pada Assessment Event sehingga penguji mengisinya di Lembar Penguji (tetap terbuka bagi dosen/preseptor penguji) dan nilainya dihitung dari jawaban berbobot. Kaprodi dan admin melihat semua jawaban masuk di `/assessment_form_submissions`; pada templat **anonim**, identitas responden hanya terlihat oleh admin.

### 6.14 Rotasi Klinik dan Enrolment Tutorial

Admin membuat **Rotasi Klinik** (`/clinical_rotations/new`: mahasiswa, periode, bagian/departemen, wahana, preseptor, tanggal) dan **Enrolment Tutorial** (`/tutorial_enrollments/new`: mahasiswa, periode, blok/sistem, tutor, tanggal; unik per mahasiswa-periode-blok; tombol aktif/selesai). Nama stase/blok harus **sama persis** (tanpa membedakan huruf besar-kecil) dengan nama blok pada Assessment Event agar event tampil ke mahasiswa.

Rotasi yang sudah punya penilaian **DOPS/Mini-CEX tidak dapat dihapus** — nilai mahasiswa wajib bertaut ke rotasinya. Untuk rotasi yang belum dinilai, jadwal DOPS/Mini-CEX dan kegiatan logbook yang menunjuknya hanya dilepas tautannya saat rotasi dihapus.

### 6.15 Taksonomi Istilah

`/admin/terminology` — mengganti label menu sidebar, judul grup, bilah bawah ponsel, dan istilah halaman Logbook Kegiatan. Kotak **Cari label** menyaring daftar; kosongkan isian untuk kembali ke bawaan. Label menu hanya berlaku pada antarmuka Bahasa Indonesia; istilah halaman berlaku di kedua bahasa. Menu baru otomatis muncul di daftar ini.

### 6.16 Data Governance

`/admin/data_governance` — sakelar **Contextual Privacy Mode** (bawaan menyala; bila server mengunci lewat variabel lingkungan `PRIVACY_MODE`, sakelar tidak dapat diubah dari sini) dan **Jejak Audit Break Glass**: 100 pembukaan identitas terakhir — siapa, kasus mana, kapan, alasan, alamat IP. Baris audit tidak pernah dihapus.

---

## Bab 7 — Privasi & Keamanan Data Pasien

<svg class="dg" viewBox="0 0 760 210" role="img" aria-label="Alur perlindungan identitas pasien: enkripsi, penyamaran, Break Glass, audit">
  <defs><marker id="ar-priv" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <rect x="10" y="30" width="170" height="70" rx="10" class="dg-box"/>
  <text x="95" y="54" class="dg-t dg-b" text-anchor="middle">Disimpan terenkripsi</text>
  <text x="95" y="72" class="dg-ts" text-anchor="middle">nama, No. RM, tgl lahir,</text>
  <text x="95" y="86" class="dg-ts" text-anchor="middle">telepon, alamat</text>
  <rect x="215" y="30" width="170" height="70" rx="10" class="dg-box-gray"/>
  <text x="300" y="54" class="dg-t dg-b" text-anchor="middle">Tampil tersamar</text>
  <text x="300" y="72" class="dg-ts" text-anchor="middle">AF*** · RM-****56 · ••••</text>
  <text x="300" y="86" class="dg-ts" text-anchor="middle">untuk semua, termasuk pemilik</text>
  <rect x="420" y="30" width="170" height="70" rx="10" class="dg-box-amber"/>
  <text x="505" y="54" class="dg-t dg-b" text-anchor="middle">Break Glass</text>
  <text x="505" y="72" class="dg-ts" text-anchor="middle">alasan ≥ 10 karakter</text>
  <text x="505" y="86" class="dg-ts" text-anchor="middle">terbuka 30 menit, akun ini saja</text>
  <rect x="625" y="30" width="125" height="70" rx="10" class="dg-box-red"/>
  <text x="687" y="54" class="dg-t dg-b" text-anchor="middle">Audit permanen</text>
  <text x="687" y="72" class="dg-ts" text-anchor="middle">siapa, kapan, IP</text>
  <text x="687" y="86" class="dg-ts" text-anchor="middle">Data Governance</text>
  <line x1="180" y1="65" x2="213" y2="65" class="dg-arrow" marker-end="url(#ar-priv)"/>
  <line x1="385" y1="65" x2="418" y2="65" class="dg-arrow" marker-end="url(#ar-priv)"/>
  <line x1="590" y1="65" x2="623" y2="65" class="dg-arrow" marker-end="url(#ar-priv)"/>
  <rect x="215" y="130" width="375" height="56" rx="10" class="dg-box-green"/>
  <text x="402" y="152" class="dg-t dg-b" text-anchor="middle">Tidak sensitif — tampil terbuka</text>
  <text x="402" y="170" class="dg-ts" text-anchor="middle">usia, kelompok usia, jenis kelamin, pekerjaan, setting klinis, kompleksitas</text>
  <text x="380" y="204" class="dg-lbl" text-anchor="middle">Privacy Mode dapat dimatikan admin di Data Governance; bawaannya menyala (gagal ke arah aman).</text>
</svg>

Prinsip yang diterapkan aplikasi:

1. **Enkripsi di basis data** untuk nama, No. RM, tanggal lahir, telepon, dan alamat pasien. Kunci enkripsi disimpan di server, terpisah dari data.
2. **Contextual Privacy Mode** menyamarkan identitas di layar untuk semua pembaca kecuali pembimbing kasus (preseptor rotasi pada tanggal kasus dan dosen verifier kasus itu). Usia, jenis kelamin, pekerjaan, dan konteks klinis bukan data sensitif dan tampil terbuka.
3. **Break Glass** membuka identitas hanya untuk akun peminta, 30 menit, dengan alasan tertulis, dan **selalu tercatat**. Gunakan hanya untuk kebutuhan pelayanan/pembelajaran yang nyata.
4. **Persetujuan pasien** dikumpulkan lewat lembar QR tanpa login yang tidak menampilkan isi kasus.
5. **Kode pasien** pada Logbook Kegiatan adalah kode acak — bukan nama, bukan No. RM.
6. **Anonimitas formulir evaluasi**: pada templat anonim, subjek yang dinilai tidak melihat identitas pengisi.
7. **Data yang keluar aplikasi** (ekspor CSV Portfolio, feed iCal, paket migrasi) **tidak memuat identitas pasien**; paket migrasi hanya membawanya bila admin server secara eksplisit memintanya.

Kewajiban pengguna: jangan menulis nama atau nomor identitas pasien pada kolom bebas (keluhan, anamnesis, catatan, judul kegiatan, refleksi) — kolom itu **tidak** terenkripsi dan tidak disamarkan.

---

## Bab 8 — Notifikasi

| Peristiwa | Penerima |
|---|---|
| Kasus dikirim untuk verifikasi | dosen/preseptor pembimbing yang ditandai |
| Kasus diverifikasi / perlu revisi / ditolak / verifikasi dibatalkan | pemilik kasus |
| Komentar baru pada kasus | pemilik atau verifier — sebelum ada verifier, pembimbing yang ditandai (lawan bicara) |
| Kegiatan diverifikasi | pemilik kegiatan |
| Permintaan DOPS / Mini-CEX / CBD / Long Case dari kasus | penilai yang ditunjuk |
| DOPS / Mini-CEX terkirim | mahasiswa |
| Pengumpulan asesmen rubrik | penguji yang ditunjuk |
| Nilai asesmen keluar | mahasiswa |
| Tingkat entrustment diperbarui | mahasiswa |
| Skor ujian tugas akhir | mahasiswa |

Semua notifikasi muncul di lonceng topbar dan halaman **Notifikasi**. **Web Push** ke perangkat (peramban desktop/Android; iPhone lewat aplikasi di Layar Utama) aktif bila server dipasangi kunci VAPID — tombol **Aktifkan Notifikasi Push** di halaman Notifikasi. Notifikasi push dapat dimatikan dari halaman yang sama.

---

## Bab 9 — Bagaimana Data Mengalir ke Capaian

<svg class="dg" viewBox="0 0 760 330" role="img" aria-label="Peta aliran data dari pencatatan ke capaian">
  <defs><marker id="ar-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="dg-arrowhead"/></marker></defs>
  <text x="120" y="22" class="dg-lbl dg-b" text-anchor="middle">SUMBER (dicatat)</text>
  <text x="380" y="22" class="dg-lbl dg-b" text-anchor="middle">DIPUTUSKAN OLEH</text>
  <text x="640" y="22" class="dg-lbl dg-b" text-anchor="middle">TAMPIL SEBAGAI</text>
  <rect x="20" y="36" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="60" class="dg-t" text-anchor="middle">Kasus Klinis</text>
  <rect x="20" y="86" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="110" class="dg-t" text-anchor="middle">Logbook Kegiatan</text>
  <rect x="20" y="136" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="160" class="dg-t" text-anchor="middle">DOPS / Mini-CEX</text>
  <rect x="20" y="186" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="210" class="dg-t" text-anchor="middle">Assessment Event (CBT/OSCE…)</text>
  <rect x="20" y="236" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="260" class="dg-t" text-anchor="middle">Rubrik / CBD / Long Case</text>
  <rect x="20" y="286" width="200" height="40" rx="8" class="dg-box"/><text x="120" y="310" class="dg-t" text-anchor="middle">Tugas Akhir</text>
  <rect x="290" y="36" width="180" height="40" rx="8" class="dg-box-amber"/><text x="380" y="60" class="dg-t" text-anchor="middle">Verifikasi pembimbing</text>
  <rect x="290" y="136" width="180" height="40" rx="8" class="dg-box-amber"/><text x="380" y="160" class="dg-t" text-anchor="middle">Penilai (skala 1–9)</text>
  <rect x="290" y="186" width="180" height="40" rx="8" class="dg-box-amber"/><text x="380" y="210" class="dg-t" text-anchor="middle">Impor CSV admin</text>
  <rect x="290" y="236" width="180" height="40" rx="8" class="dg-box-amber"/><text x="380" y="260" class="dg-t" text-anchor="middle">Lembar Penguji</text>
  <rect x="290" y="286" width="180" height="40" rx="8" class="dg-box-amber"/><text x="380" y="310" class="dg-t" text-anchor="middle">Skor penguji</text>
  <rect x="540" y="36" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="60" class="dg-t" text-anchor="middle">Peta EPA &amp; target kasus</text>
  <rect x="540" y="86" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="110" class="dg-t" text-anchor="middle">Portfolio &amp; Kalender</text>
  <rect x="540" y="136" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="160" class="dg-t" text-anchor="middle">Radar kompetensi</text>
  <rect x="540" y="186" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="210" class="dg-t" text-anchor="middle">Nilai unit &amp; persentil kohort</text>
  <rect x="540" y="236" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="260" class="dg-t" text-anchor="middle">Jurnal Umpan Balik</text>
  <rect x="540" y="286" width="200" height="40" rx="8" class="dg-box-green"/><text x="640" y="310" class="dg-t" text-anchor="middle">Dashboard Analitik</text>
  <line x1="220" y1="56" x2="288" y2="56" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="470" y1="56" x2="538" y2="56" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="220" y1="106" x2="538" y2="106" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="220" y1="156" x2="288" y2="156" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="470" y1="156" x2="538" y2="156" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="220" y1="206" x2="288" y2="206" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="470" y1="206" x2="538" y2="206" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="220" y1="256" x2="288" y2="256" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="470" y1="256" x2="538" y2="256" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="220" y1="306" x2="288" y2="306" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <line x1="470" y1="306" x2="538" y2="306" class="dg-arrow" marker-end="url(#ar-flow)"/>
  <path d="M470,166 L505,166 L505,300 L538,300" fill="none" class="dg-arrow dg-dash" marker-end="url(#ar-flow)"/>
  <path d="M470,216 L520,216 L520,250 L538,250" fill="none" class="dg-arrow dg-dash" marker-end="url(#ar-flow)"/>
</svg>

Beberapa konsekuensi praktis:

- Kasus **belum diverifikasi** tidak dihitung ke target kasus dan tidak menulis Peta EPA.
- DOPS/Mini-CEX **draf** tidak masuk radar, capaian, jurnal, maupun Dashboard Analitik.
- Nilai ujian tampil di Peta Kompetensi **hanya pada periode event-nya**; capaian per ranah butuh dimensi yang dipetakan admin.
- Nilai Learning Unit adalah "capaian dari komponen yang sudah dinilai" — bukan nilai akhir sebelum semua komponen masuk.

---

## Bab 10 — Pertanyaan yang Sering Diajukan

**Saya mendaftar tetapi tidak bisa masuk: "harus mengonfirmasi email".**
Server tidak mengirim surel. Minta admin membuka **Konfigurasi → Pengguna → Sunting → Konfirmasi Sekarang**.

**Menu Konfigurasi / Coaching Center tidak muncul.**
Sidebar mengikuti **peran aktif**. Ganti peran di topbar. Konfigurasi hanya untuk akun berperan admin.

**Event asesmen tidak tampil di Rubric-based Assessment / Asesmen Saya.**
Periksa: (1) event berstatus **Terbit**; (2) **Program Studi** di profil Anda sama dengan prodi event; (3) bila event dibatasi blok/stase, nama blok pada **enrolment tutorial aktif** atau **rotasi berjalan** Anda harus sama dengan nama blok event; (4) batas waktu pengumpulan belum lewat. Event ujian tulis/praktik memang tidak tampil di sini — nilainya diimpor admin dan muncul di **Evaluasi Akademik**.

**Tombol Minta DOPS / Mini-CEX menolak: "Tidak ada rotasi klinis yang mencakup tanggal kasus".**
Permintaan dari kasus membutuhkan **rotasi klinik** Anda yang mencakup tanggal kasus (atau sedang berjalan) dan rotasi itu harus punya **preseptor**. Minta admin melengkapi jadwal rotasi.

**Semester di formulir kegiatan tidak terisi otomatis.**
Terisi hanya bila tepat satu periode akademik mencakup tanggal kegiatan. Pilih manual bila periode tumpang-tindih atau belum dibuat admin.

**Identitas pasien tampak `AF***` padahal saya pemiliknya.**
Itu Privacy Mode — berlaku untuk semua, termasuk pemilik kasus; hanya pembimbing kasus yang melihatnya langsung. Gunakan **Break Glass** bila perlu, dengan alasan yang benar; pembukaan tercatat.

**Kegiatan lama saya tampil "Klinis/Non-Klinis" tanpa domain.**
Kegiatan yang dicatat sebelum taksonomi ada tidak ditebak domainnya. Sunting kegiatan dan pilih domain — hanya jika Anda ingin.

**Kartu Pemenuhan Target Kasus tidak muncul.**
Admin belum menetapkan target untuk prodi Anda, atau Program Studi Anda kosong. Hanya kasus **terverifikasi** yang dihitung.

**Posisi terhadap kohort tidak tampil.**
Kohort untuk tipe asesmen & periode itu kurang dari 3 mahasiswa, atau Anda belum punya nilai dinilai pada periode tersebut.

**Saya dosen sekaligus mahasiswa; kenapa tidak bisa memverifikasi kasus saya sendiri?**
Disengaja — verifikasi harus dilakukan orang lain.

**Bagaimana menghapus akun?**
Halaman **Pengaturan Akun** sengaja tidak menyediakan tombol hapus akun: logbook, kasus, dan nilai Anda adalah rekam jejak pendidikan yang dikelola program studi. Hubungi admin program studi.

**Kaprodi: Program Studi Binaan tidak bisa saya ubah di Sunting Profil.**
Disengaja — prodi itu membatasi data yang boleh Anda lihat dan ubah. Minta admin mengubahnya di **Konfigurasi → Pengguna → Sunting**.

**Admin: periode, rotasi, event, atau butir kompetensi menolak dihapus.**
Data itu sudah dipakai — oleh rotasi/event/milestone (periode), penilaian DOPS/Mini-CEX (rotasi), nilai mahasiswa (event), atau keputusan EPA mahasiswa (butir kompetensi). Pesan penolakan menyebut pemakaiannya. Data yang sudah dipakai sebaiknya dibiarkan; untuk event, ubah statusnya menjadi **Ditutup**.

---

## Bab 11 — Pindah ke jejak.pro

Seluruh data JEJAK Essential dapat dipindahkan ke jejak.pro tanpa ketik ulang. Admin server menjalankan `bin/rails migration:check` (memeriksa kesiapan data) lalu `bin/rails migration:export` untuk membuat paket berisi salinan lengkap tabel, berkas CSV berformat kontrak jejak.pro, dan lampiran; identitas pasien hanya ikut bila diminta secara eksplisit. Paket itu kemudian diimpor di jejak.pro dengan uji coba terlebih dahulu. Rincian teknis ada pada dokumen `MIGRASI_KE_JEJAK_PRO.md` di paket instalasi.

---

## Lampiran A — Daftar Alamat Halaman

| Menu | Alamat |
|---|---|
| Beranda | `/dashboard` |
| Longitudinal Portfolio | `/portfolio` (ekspor: `/portfolio/export`) |
| Profil Saya / Sunting | `/profile`, `/profile/edit` |
| Pengaturan Saya / Pengaturan Akun | `/pengaturan`, `/users/edit` |
| Notifikasi | `/notifications` |
| Kasus Klinis / Validasi Kasus / Riwayat Verifikasi | `/clinical_cases`, `/clinical_cases?scope=to_verify`, `/clinical_cases?scope=reviewed` |
| Logbook Kegiatan / Validasi Kegiatan / Kalender | `/activity_logs`, `/activity_logs?scope=to_verify`, `/kalender` |
| Rotasi Klinik | `/clinical_rotations` |
| Enrolment Tutorial | `/tutorial_enrollments` |
| Refleksi | `/reflection_entries` |
| Tugas Akhir | `/final_projects` |
| Evaluasi Akademik | `/nilai-ujian` |
| Workplace Assessment (DOPS/Mini-CEX) | `/asesmen`, `/dops_evaluations/new`, `/mini_cex_evaluations/new` |
| Rubric-based Assessment (mahasiswa) | `/student/assessments` |
| Lembar Penguji (pembimbing) | `/examiner_evaluations` |
| Jurnal Umpan Balik | `/student/feedback_journal` |
| Assessment Form Builder / jawaban | `/assessment_form_templates`, `/assessment_form_submissions` |
| Peta Kompetensi | `/capaian-belajar` |
| Peta EPA & Entrustment | `/dashboard/entrustment` |
| Dashboard Analitik | `/analitik` |
| Daftar Mahasiswa / Pencarian | `/cari` |
| Tahun/Periode Akademik | `/academic_periods` |
| Program Studi | `/study_programs` |
| Pengguna / Impor CSV | `/admin/users`, `/admin/users/import` |
| Relabel Prodi Mahasiswa | `/admin/student_relabel/new` |
| Assessment Events | `/admin/assessment_events` |
| Jadwal DOPS & Mini-CEX | `/admin/evaluation_schedules` |
| Kerangka Kompetensi | `/competency_frameworks` |
| Blueprint Asesmen | `/assessment_blueprints` |
| Learning Unit & Matrix | `/admin/learning_units` |
| Target Kasus Logbook | `/admin/logbook_case_targets` |
| Domain Kegiatan Akademik | `/admin/academic_activity_domains` |
| Master Diagnosis / Keterampilan / Obat | `/admin/diagnosis_definitions`, `/admin/skill_definitions`, `/admin/medication_definitions` |
| Taksonomi Istilah | `/admin/terminology` |
| Data Governance | `/admin/data_governance` |
| Lembar persetujuan pasien (publik) | `/persetujuan/<token>` |
| Panduan ini | `/panduan` |

## Lampiran B — Glosarium

| Istilah | Arti |
|---|---|
| **Break Glass** | Pembukaan identitas pasien yang tersamar, beralasan, 30 menit, dan selalu diaudit. |
| **CBD / Long Case** | Asesmen berbasis kasus (Case-Based Discussion / Long Case) yang diinisiasi dari Kasus Klinis. |
| **DOPS** | Direct Observation of Procedural Skills — penilaian langsung satu prosedur, 10 dimensi skala 1–9. |
| **Mini-CEX** | Mini Clinical Evaluation Exercise — penilaian satu pertemuan pasien, 6 dimensi + penilaian global. |
| **EPA / Entrustment** | Entrustable Professional Activity — tingkat kepercayaan 1–5 per ranah kompetensi. |
| **FKTP / FKRTL** | Fasilitas Kesehatan Tingkat Pertama (pelayanan primer) / Rujukan Tingkat Lanjut (rumah sakit). |
| **Assessment Event** | Satu ujian/penilaian pada satu periode; wadah semua nilai. |
| **Percobaan (attempt)** | Satu kali keikutsertaan mahasiswa pada sebuah event; nilai tertinggi menjadi wakil. |
| **Learning Unit** | Blok/modul yang nilainya disusun dari beberapa event lewat Assessment Matrix berbobot. |
| **Kohort** | Seluruh mahasiswa (gabungan sarjana + profesi) dengan nilai pada tipe asesmen & periode yang sama. |
| **Privacy Mode** | Penyamaran identitas pasien di layar untuk semua pembaca selain pembimbing kasus. |
| **Rotasi Klinik / Stase** | Penempatan mahasiswa profesi di satu bagian & wahana pada rentang tanggal. |
| **Enrolment Tutorial** | Penempatan mahasiswa sarjana pada blok/sistem dengan dosen tutor. |
| **Taksonomi Istilah** | Penggantian label menu/istilah oleh admin tanpa mengubah kode. |
