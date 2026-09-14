class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Biodata profil — meniru pengelompokan halaman Profil jejak.pro (Biodata
  # Pribadi / Akademik / Informasi Kepegawaian), dipersempit ke tier Dasar:
  # tanpa identitas ilmiah (ORCID/Scopus), kredensial preseptor, dan riwayat
  # pendidikan formal.
  def change
    # ── Identitas & kontak (semua peran) ──
    add_column :users, :identifier_number, :string   # NPM/NIM (mahasiswa) atau NIP/NIDN (dosen/tendik)
    add_column :users, :phone, :string
    add_column :users, :gender, :string              # Laki-laki / Perempuan
    add_column :users, :birth_place, :string
    add_column :users, :birth_date, :date
    add_column :users, :address, :text

    # ── Akademik (mahasiswa) ──
    add_column :users, :cohort_year, :integer        # angkatan, mis. 2024

    # ── Kepegawaian (dosen/preseptor/tendik) ──
    add_column :users, :work_unit, :string           # departemen/bagian/unit kerja
    add_column :users, :position, :string            # jabatan
    add_column :users, :profession_category, :string # Dokter Umum, Dokter Spesialis, ...
    add_column :users, :specialization, :string

    add_index :users, :identifier_number, algorithm: :concurrently
  end
end
