require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:budi) }

  test "menolak akses tanpa login" do
    sign_out users(:budi)
    get search_path
    assert_redirected_to new_user_session_path
  end

  test "kosongkan hasil kalau query kosong" do
    get search_path
    assert_response :success
    assert_no_match users(:siti).email, response.body
  end

  test "menemukan pengguna lewat nama atau email" do
    get search_path, params: { q: "siti" }
    assert_response :success
    assert_match users(:siti).full_name, response.body
  end

  def card_for(user)
    Nokogiri::HTML5(response.body).css("a, div").find { |el| el["class"].to_s.include?("rounded-xl ring-1") && el.text.include?(user.email) }
  end

  test "kartu mahasiswa mengarah ke Peta EPA bagi dosen" do
    get search_path, params: { q: "siti" }
    card = card_for(users(:siti))
    assert_equal "a", card.name
    assert_equal entrustment_decisions_path(student_id: users(:siti).id), card["href"]
  end

  test "kartu mahasiswa mengarah ke Peta EPA bagi kaprodi, dan halamannya bisa dibuka" do
    sign_in users(:dedi)
    get search_path, params: { q: "siti" }
    assert_equal entrustment_decisions_path(student_id: users(:siti).id), card_for(users(:siti))["href"]

    get entrustment_decisions_path(student_id: users(:siti).id)
    assert_response :success
    assert_match users(:siti).full_name, response.body
  end

  test "kartu mengarah ke sunting pengguna bagi admin" do
    users(:budi).roles << roles(:admin)
    get search_path, params: { q: "wati" }
    assert_equal edit_admin_user_path(users(:wati)), card_for(users(:wati))["href"]
  end

  test "kartu tanpa tujuan tetap tampil tanpa tautan bagi mahasiswa" do
    sign_in users(:siti)
    get search_path, params: { q: "wati" }
    assert_equal "div", card_for(users(:wati)).name
  end
end
