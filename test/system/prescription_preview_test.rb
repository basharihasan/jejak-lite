require "application_system_test_case"

class PrescriptionPreviewTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  # Regresi: pratinjau membaca singkatan sediaan dari kolom yang tidak ada,
  # sehingga "tab" hilang dan pratinjau berbeda dari resep yang disimpan
  # (PrescriptionItem#prescription_line).
  test "pratinjau R/ memuat singkatan sediaan seperti resep yang disimpan" do
    sign_in users(:siti)
    visit new_clinical_case_path

    assert_selector '[data-wizard-target="dot"][aria-current="step"][data-wizard-index-param="0"]'
    find('[data-wizard-target="dot"][data-wizard-index-param="4"]').click
    click_on "+ Tambah Obat"

    within('[data-prescription-target="rows"]') do
      find('[data-field="medication_name"]').set("Parasetamol")
      find('[data-field="dosage_form"]').select "Tablet"
      find('[data-field="strength"]').set("500 mg")
      find('[data-field="quantity"]').set("X")
      find('[data-field="signa"]').set("3 dd tab I p.c.")
    end

    assert_selector '[data-prescription-target="preview"]', text: "R/ Parasetamol tab 500 mg No. X"
    assert_selector '[data-prescription-target="preview"]', text: "S 3 dd tab I p.c."
  end
end
