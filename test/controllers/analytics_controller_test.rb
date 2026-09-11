require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa tidak boleh mengakses" do
    sign_in users(:siti)
    get analytics_path
    assert_response :redirect
  end

  test "dosen melihat mahasiswa bimbingan (evaluator DOPS/Mini-CEX) tapi bukan bagian preseptor/prodi" do
    sign_in users(:budi)
    get analytics_path
    assert_response :success
    assert_match users(:siti).full_name, response.body
    assert_no_match "Mahasiswa di Wahana Anda", response.body
    assert_no_match "Program Studi", response.body
  end

  test "preseptor melihat mahasiswa di rotasi yang dibimbingnya" do
    sign_in users(:wati)
    get analytics_path
    assert_response :success
    assert_match clinical_rotations(:wati_preceptored_rotation).station_name, response.body
    assert_no_match "Mahasiswa Bimbingan", response.body
  end

  test "kaprodi hanya melihat mahasiswa program studinya sendiri, tanpa pilihan pindah prodi" do
    sign_in users(:dedi)
    get analytics_path
    assert_response :success
    assert_match users(:siti).full_name, response.body
    assert_no_match "<select", response.body
  end

  test "admin melihat ketiga bagian sekaligus" do
    admin = users(:budi)
    admin.roles << roles(:admin)
    sign_in admin

    get analytics_path
    assert_response :success
    assert_match "Mahasiswa Bimbingan", response.body
    assert_match "Mahasiswa di Wahana Anda", response.body
    assert_match "Program Studi", response.body
  end
end
