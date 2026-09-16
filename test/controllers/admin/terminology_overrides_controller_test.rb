require "test_helper"

# Konfigurasi → Taksonomi Istilah: admin mengganti label menu & istilah.
class Admin::TerminologyOverridesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:budi)
    @admin.roles << roles(:admin)
    sign_in @admin
  end

  test "bukan admin ditolak" do
    sign_in users(:siti)
    get admin_terminology_path
    assert_redirected_to dashboard_path

    patch admin_terminology_path, params: { terms: { "nav.home" => "Rumah" } }
    assert_not TerminologyOverride.exists?
  end

  test "halaman menampilkan semua label menu & istilah, dikelompokkan" do
    get admin_terminology_path

    assert_response :success
    assert_select "aside#sidebar a[href=?]", admin_terminology_path, text: "Taksonomi Istilah"
    Terminology::SECTIONS.each_value { |title| assert_select "h2", text: title }
    assert_select "input[name=?][placeholder=?]", "terms[nav.clinical_rotations]", "Rotasi Klinik"
    assert_select "input[name=?][placeholder=?]", "terms[nav.groups.configuration]", "Konfigurasi"
    assert_select "input[name=?][placeholder=?]", "terms[nav.mobile.activity]", "Log Keg."
    assert_select "input[name=?][placeholder=?]", "terms[terms.activity_subdomain]", "Subdomain / Kategori"
  end

  test "label menu pengganti tampil di sidebar; dikosongkan kembali ke bawaan" do
    patch admin_terminology_path, params: { terms: {
      "nav.clinical_rotations" => "  Stase Klinik  ", "nav.groups.configuration" => "Pengaturan Sistem", "nav.home" => ""
    } }
    assert_redirected_to admin_terminology_path
    assert_equal "Stase Klinik", TerminologyOverride.find_by(key: "nav.clinical_rotations").value
    assert_equal @admin, TerminologyOverride.find_by(key: "nav.clinical_rotations").updated_by

    get dashboard_path
    assert_select "aside#sidebar a[href=?]", clinical_rotations_path, text: "Stase Klinik"
    assert_select "aside#sidebar p", text: "Pengaturan Sistem"
    assert_select "aside#sidebar p", text: "Konfigurasi", count: 0

    patch admin_terminology_path, params: { terms: { "nav.clinical_rotations" => "", "nav.groups.configuration" => "Konfigurasi" } }
    assert_not TerminologyOverride.exists?, "isian kosong / sama dengan bawaan menghapus penggantian"
    get dashboard_path
    assert_select "aside#sidebar a[href=?]", clinical_rotations_path, text: "Rotasi Klinik"
  end

  test "istilah pengganti dipakai form Logbook Kegiatan di kedua bahasa; label menu hanya di Bahasa Indonesia" do
    patch admin_terminology_path, params: { terms: {
      "terms.activity_subdomain" => "Sub Kategori", "nav.activity_logs" => "Catatan Kegiatan"
    } }

    get new_activity_log_path
    assert_select "label", text: "Sub Kategori"
    assert_select "aside#sidebar a[href=?]", activity_logs_path, text: "Catatan Kegiatan"

    @admin.update!(locale_preference: "en")
    get new_activity_log_path
    assert_select "label", text: "Sub Kategori"
    assert_select "aside#sidebar a[href=?]", activity_logs_path, text: "Activity Logbook"
  end

  test "label terlalu panjang atau kunci asing ditolak tanpa menyimpan apa pun" do
    patch admin_terminology_path, params: { terms: {
      "nav.home" => "Rumah", "nav.users" => "x" * (TerminologyOverride::MAX_LENGTH + 1)
    } }

    assert_response :unprocessable_entity
    assert_match "Belum disimpan", response.body
    assert_not TerminologyOverride.exists?
    assert_select "input[name=?][value=?]", "terms[nav.home]", "Rumah"

    patch admin_terminology_path, params: { terms: { "chrome.sign_out" => "Pergi" } }
    assert_redirected_to admin_terminology_path
    assert_not TerminologyOverride.exists?, "kunci di luar daftar diabaikan strong params"
  end
end
