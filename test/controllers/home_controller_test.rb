require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "landing page JEJAK Essential terbuka tanpa login dan mencantumkan AIPKI" do
    get root_path

    assert_response :success
    assert_match "JEJAK Essential", response.body
    assert_match "Asosiasi Institusi Pendidikan Kedokteran Indonesia", response.body
    assert_select "section#aipki"
    assert_select "img[alt='Logo Diktisaintek Berdampak']"
    assert_select "a[href=?]", new_user_session_path
  end

  test "beranda pengguna login mencantumkan peran AIPKI" do
    sign_in users(:budi)

    get dashboard_path

    assert_response :success
    assert_match "dikembangkan dengan dukungan AIPKI", response.body
  end

  test "beranda menutup dengan narasi jejak.pro yang menyesuaikan peran aktif" do
    sign_in users(:budi) # active_role: dosen

    get dashboard_path

    assert_select "a[href='https://jejak.pro'][target='_blank'][rel='noopener']"
    assert_select "[data-controller='upgrade-showcase'] [role='tab']", 3
    assert_select "[role='tabpanel'][hidden]", 2
    assert_select "#jejak-pro-upgrade-body[hidden]" # tertutup secara bawaan
    assert_select "button[aria-controls='jejak-pro-upgrade-body'][aria-expanded='false']"
    assert_match "bank soal prodi", response.body
    assert_no_match "dikte suara", response.body # narasi khusus mahasiswa
  end
end
