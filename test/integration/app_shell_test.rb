require "test_helper"

# Cangkang UI (Fase 22): sidebar berkelompok mengikuti peran aktif, topbar,
# bilah bawah mobile, dan preferensi tampilan.
class AppShellTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa melihat grup dasar tanpa Coaching Center dan Konfigurasi" do
    sign_in users(:siti)
    get dashboard_path

    assert_response :success
    assert_select "aside#sidebar" do
      assert_select "p", text: "Ikhtisar"
      assert_select "p", text: "Perjalanan Belajar"
      assert_select "p", text: "Asesmen"
      assert_select "p", text: /Kompetensi/
      assert_select "a[href=?]", portfolio_path, text: "Longitudinal Portfolio"
      assert_select "p", text: "Coaching Center", count: 0
      assert_select "p", text: "Konfigurasi", count: 0
    end
    assert_select "header a[href=?]", search_path
    assert_select ".mobile-bottom-nav a[href=?]", assessments_path
  end

  test "dosen melihat Coaching Center dengan lencana kasus menunggu, tanpa Konfigurasi" do
    sign_in users(:budi)
    get dashboard_path

    pending = ClinicalCase.awaiting_verification.count
    assert_select "aside#sidebar" do
      assert_select "p", text: "Coaching Center"
      assert_select "a[href=?]", clinical_cases_path(scope: "to_verify"), text: /Validasi Kasus Klinis/
      assert_select "a[href=?]", analytics_path
      assert_select "p", text: "Konfigurasi", count: 0
      assert_select "a[href=?]", portfolio_path, count: 0
    end
    assert_select ".mobile-bottom-nav a[href=?]", clinical_cases_path(scope: "to_verify")
    assert_match(/#{pending}/, response.body) if pending.positive?
  end

  test "admin melihat grup Konfigurasi" do
    admin_user = users(:budi)
    admin_user.roles << roles(:admin)
    admin_user.update!(active_role: roles(:admin))
    sign_in admin_user

    get dashboard_path

    assert_select "aside#sidebar" do
      assert_select "p", text: "Konfigurasi"
      assert_select "a[href=?]", academic_periods_path
      assert_select "a[href=?]", exam_imports_path
      assert_select "a[href=?]", competency_frameworks_path
      assert_select "a[href=?]", assessment_blueprints_path
    end
    # Pengalih peran tampil di topbar karena akun ini punya >1 peran.
    assert_select "header select#role_code option", minimum: 2
  end

  test "sidebar menandai menu halaman yang sedang dibuka" do
    sign_in users(:siti)
    get clinical_cases_path

    assert_select "aside#sidebar a.bg-indigo-600[href=?]", clinical_cases_path
    assert_select "aside#sidebar [data-controller=accordion][data-accordion-open-value=true] [data-accordion-target=content]:not(.hidden)", minimum: 1
  end

  test "halaman tamu tidak memuat sidebar" do
    get new_user_session_path

    assert_response :success
    assert_select "aside#sidebar", count: 0
  end

  test "preferensi tampilan tersimpan dan terpasang di html" do
    sign_in users(:siti)

    get my_settings_path
    assert_response :success

    patch update_appearance_settings_path, params: { user: { theme_preference: "dark", font_size_preference: "large" } }
    assert_redirected_to my_settings_path
    assert_equal "dark", users(:siti).reload.theme_preference

    get dashboard_path
    assert_select "html[data-theme-preference=dark][data-font-size-preference=large]"
  end

  test "tombol tema topbar menyimpan lewat JSON" do
    sign_in users(:siti)

    patch update_appearance_settings_path, params: { user: { theme_preference: "light" } }, as: :json
    assert_response :no_content
    assert_equal "light", users(:siti).reload.theme_preference
  end

  test "nilai preferensi di luar pilihan ditolak" do
    sign_in users(:siti)

    patch update_appearance_settings_path, params: { user: { theme_preference: "neon" } }
    assert_response :unprocessable_entity
    assert_equal "system", users(:siti).reload.theme_preference
  end
end
