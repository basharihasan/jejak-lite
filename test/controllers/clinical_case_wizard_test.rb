require "test_helper"

# Paket Dasar Pilar A: wizard kasus 6 langkah — pemeriksaan penunjang,
# Simpan Draf di setiap langkah, dan galat yang menunjuk langkah & baris.
class ClinicalCaseWizardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:siti) }

  test "hasil pemeriksaan penunjang tersimpan dan tampil di halaman kasus" do
    post clinical_cases_path, params: { clinical_case: {
      case_date: Date.current, chief_complaint: "Batuk berdahak 3 minggu",
      laboratory_results: "BTA sputum positif 2+", radiology_results: "Foto toraks: infiltrat apeks kanan",
      other_investigations: "Tes cepat molekuler: MTB terdeteksi"
    } }

    kasus = ClinicalCase.order(:created_at).last
    assert_redirected_to clinical_case_path(kasus)
    assert_equal "BTA sputum positif 2+", kasus.laboratory_results

    follow_redirect!
    assert_match "Pemeriksaan Penunjang", response.body
    assert_match "infiltrat apeks kanan", response.body
    assert_match "MTB terdeteksi", response.body
  end

  test "penanda langkah adalah tombol lompat ke langkah masing-masing" do
    get new_clinical_case_path
    assert_response :success

    doc = Nokogiri::HTML5(response.body)
    dots = doc.css('[data-wizard-target="dot"]')
    assert_equal ClinicalCase::WIZARD_STEPS.size, dots.size
    dots.each_with_index do |dot, i|
      assert_equal "button", dot.name
      assert_equal "button", dot["type"]
      assert_equal "wizard#goTo", dot["data-action"]
      assert_equal i.to_s, dot["data-wizard-index-param"]
      assert_includes dot["aria-label"], ClinicalCase::WIZARD_STEPS[i]
      assert_nil dot.ancestors("form").first, "penanda di luar <form> supaya tak ikut submit"
    end
  end

  test "draf tersimpan hanya dengan isian langkah pertama" do
    assert_difference "ClinicalCase.count", 1 do
      post clinical_cases_path, params: { clinical_case: { case_date: Date.current, chief_complaint: "Demam" } }
    end
    assert_equal "draft", ClinicalCase.order(:created_at).last.status
  end

  test "galat pada baris resep menunjuk langkah Terapi & Resep dan wizard membuka langkah itu" do
    post clinical_cases_path, params: { clinical_case: {
      case_date: Date.current, chief_complaint: "Faringitis",
      prescription_items_attributes: { "0" => { medication_name: "", strength: "500 mg", signa: "3 dd 1" } }
    } }

    assert_response :unprocessable_entity
    assert_match "Langkah 5 · Terapi &amp; Resep (resep)", response.body
    assert_match "Baris ini bermasalah", response.body
    assert_select "[data-controller='wizard'][data-wizard-current-value='4']"
  end

  test "galat keluhan utama menunjuk langkah pertama" do
    post clinical_cases_path, params: { clinical_case: { case_date: Date.current, chief_complaint: "" } }

    assert_response :unprocessable_entity
    assert_match "Langkah 1 · Identitas &amp; Demografi", response.body
    assert_select "[data-controller='wizard'][data-wizard-current-value='0']"
  end
end
