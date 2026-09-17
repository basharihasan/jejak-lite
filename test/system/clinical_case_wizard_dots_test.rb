require "application_system_test_case"

class ClinicalCaseWizardDotsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  test "klik penanda langkah melompat langsung ke langkah itu" do
    sign_in users(:siti)
    visit new_clinical_case_path

    assert_text "LANGKAH 1 DARI 6"
    # aria-current dipasang oleh Stimulus saat connect — tunggu itu dulu supaya
    # klik tidak mendahului pemuatan JS (pernah gagal acak di CI).
    assert_selector '[data-wizard-target="dot"][aria-current="step"][data-wizard-index-param="0"]'
    find('[data-wizard-target="dot"][data-wizard-index-param="3"]').click
    assert_text "LANGKAH 4 DARI 6"
    assert_selector '[data-wizard-target="dot"][aria-current="step"][data-wizard-index-param="3"]'

    find('[data-wizard-target="dot"][data-wizard-index-param="0"]').click
    assert_text "LANGKAH 1 DARI 6"
  end
end
