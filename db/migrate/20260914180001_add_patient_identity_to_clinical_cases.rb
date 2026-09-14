class AddPatientIdentityToClinicalCases < ActiveRecord::Migration[8.1]
  def change
    # Kolom identitas pasien — terenkripsi lewat `encrypts` di model. Tanggal
    # lahir disimpan sebagai string ISO karena Active Record Encryption hanya
    # untuk kolom teks.
    add_column :clinical_cases, :patient_name, :text
    add_column :clinical_cases, :patient_medical_record_number, :text
    add_column :clinical_cases, :patient_birth_date, :text
    add_column :clinical_cases, :patient_phone, :text
    add_column :clinical_cases, :patient_address, :text
    # Bukan data sensitif (keputusan pengelola 14 Sep 2026): usia persis &
    # pekerjaan tampil tanpa Break Glass.
    add_column :clinical_cases, :patient_age, :integer
    add_column :clinical_cases, :patient_occupation, :string
    add_column :clinical_cases, :icd10_code, :string
    add_column :clinical_cases, :skdi_level, :string
  end
end
