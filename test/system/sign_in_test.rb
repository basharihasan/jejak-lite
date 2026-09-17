require "application_system_test_case"

class SignInTest < ApplicationSystemTestCase
  test "login salah menampilkan pesan, login benar masuk ke aplikasi" do
    visit new_user_session_path
    fill_in "Email", with: users(:siti).email
    fill_in "Kata Sandi", with: "salah"
    click_on "Masuk"
    assert_text "Email atau kata sandi salah"

    fill_in "Email", with: users(:siti).email
    fill_in "Kata Sandi", with: "password123"
    click_on "Masuk"
    assert_no_current_path new_user_session_path
    assert_text users(:siti).full_name
  end
end
