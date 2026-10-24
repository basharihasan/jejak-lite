require "application_system_test_case"

# Dropdown nama (mahasiswa/dosen) bisa diketik untuk mencari — lihat
# searchable_select_controller.js. Select asli tetap jadi nilai yang dikirim.
class SearchableSelectTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def open_case_form
    sign_in users(:siti)
    visit new_clinical_case_path
    # Kotak ketik dipasang Stimulus saat connect — tunggu itu dulu.
    find("input[role='combobox']#clinical_case_supervisor_id")
  end

  def supervisor_value
    find("select[name='clinical_case[supervisor_id]']", visible: :hidden).value
  end

  test "mengetik sebagian nama menyaring daftar dan klik memilihnya" do
    combobox = open_case_form
    combobox.set("wat")

    assert_selector "[role='option']", text: "Wati Preseptor"
    assert_no_selector "[role='option']", text: "Budi Dosen"
    find("[role='option']", text: "Wati Preseptor").click

    assert_no_selector "[role='listbox']"
    assert_equal "Wati Preseptor", combobox.value
    assert_equal users(:wati).id.to_s, supervisor_value
  end

  test "tiap kata dicocokkan terpisah dan Enter memilih hasil teratas" do
    combobox = open_case_form
    combobox.set("PRESEPTOR wat")

    assert_selector "[role='option']", count: 1
    combobox.send_keys(:enter)

    assert_equal users(:wati).id.to_s, supervisor_value
  end

  test "teks yang tidak cocok kembali ke pilihan; teks kosong menghapus pilihan" do
    combobox = open_case_form
    combobox.set("budi")
    combobox.send_keys(:enter)
    assert_equal users(:budi).id.to_s, supervisor_value

    combobox.set("zzz")
    assert_text "Tidak ada yang cocok dengan pencarian."
    combobox.send_keys(:tab)
    assert_equal "Budi Dosen", combobox.value
    assert_equal users(:budi).id.to_s, supervisor_value

    combobox.set("", clear: :backspace)
    combobox.send_keys(:tab)
    assert_equal "", supervisor_value
  end

  test "klik label membuka daftar dan Escape menutupnya" do
    combobox = open_case_form
    find("label[for='clinical_case_supervisor_id']").click

    assert_selector "[role='listbox'] [role='option']", text: "Budi Dosen"
    combobox.send_keys(:escape)
    assert_no_selector "[role='listbox']"
  end

  test "kembali lewat cache Turbo tidak menggandakan kotak ketik" do
    open_case_form
    find("a[href='#{dashboard_path}']", match: :first).click
    assert_no_selector "input#clinical_case_supervisor_id"
    go_back

    assert_selector "input[role='combobox']#clinical_case_supervisor_id", count: 1
    assert_selector "select[name='clinical_case[supervisor_id]']", visible: :hidden, count: 1
  end

  test "pilihan wajib divalidasi di kotak ketik lalu terkirim setelah dipilih" do
    UserRole.create!(user: users(:budi), role: roles(:admin))
    sign_in users(:budi)
    visit admin_assessment_event_path(assessment_events(:cbt_blok))

    form = find("form[action='#{add_instance_admin_assessment_event_path(assessment_events(:cbt_blok))}']")
    within(form) do
      student = find("input[role='combobox']#student_id")
      click_on "Daftarkan"
      assert_equal "Pilih salah satu dari daftar.", student.evaluate_script("this.validationMessage")

      student.set("siti")
      student.send_keys(:enter)
      examiner = find("input[role='combobox']#examiner_id")
      examiner.set("wati")
      examiner.send_keys(:enter)
      click_on "Daftarkan"
    end

    assert_text "Siti Mahasiswa didaftarkan"
    assert_equal users(:wati), AssessmentInstance.where(assessment_event: assessment_events(:cbt_blok), student: users(:siti)).order(:attempt_number).last.examiner
  end
end
