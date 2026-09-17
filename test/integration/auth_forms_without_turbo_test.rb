require "test_helper"

# Formulir autentikasi dikirim tanpa Turbo: jawaban login yang berhasil
# (303 → 200) bisa dianggap "tidak diarahkan" oleh Turbo bila fetch dibungkus
# ekstensi browser, sehingga login tampak diam. Tombol Google wajib POST.
class AuthFormsWithoutTurboTest < ActionDispatch::IntegrationTest
  AUTH_PAGES = {
    "masuk" => -> { new_user_session_path },
    "daftar" => -> { new_user_registration_path },
    "lupa kata sandi" => -> { new_user_password_path },
    "instruksi konfirmasi" => -> { new_user_confirmation_path }
  }.freeze

  AUTH_PAGES.each do |label, path|
    test "formulir #{label} dikirim tanpa Turbo" do
      get instance_exec(&path)
      assert_response :success
      form = Nokogiri::HTML5(response.body).at_css("main form, form[action^='/users']")
      assert form, "formulir #{label} harus ada"
      assert_equal "false", form["data-turbo"]
    end
  end

  test "tombol Google berupa formulir POST tanpa Turbo" do
    # Provider Google hanya terdaftar bila ENV terisi; tampilkan tombolnya
    # sementara tanpa menyentuh konfigurasi OmniAuth.
    original = Devise.method(:omniauth_providers)
    Devise.define_singleton_method(:omniauth_providers) { [ :google_oauth2 ] }
    [ new_user_session_path, new_user_registration_path ].each do |path|
      get path
      form = Nokogiri::HTML5(response.body).at_css("form[action='#{user_google_oauth2_omniauth_authorize_path}']")
      assert form, "tombol Google di #{path} harus berupa formulir"
      assert_equal "post", form["method"]
      assert_equal "false", form["data-turbo"]
    end
  ensure
    Devise.define_singleton_method(:omniauth_providers, original)
  end

  test "login salah tetap menampilkan pesan; login benar diarahkan ke beranda" do
    post user_session_path, params: { user: { email: users(:siti).email, password: "salah" } }
    assert_response :unprocessable_content
    assert_match "Email atau kata sandi salah", response.body

    post user_session_path, params: { user: { email: users(:siti).email, password: "password123" } }
    assert_response :see_other
  end
end
