require "test_helper"

class PanduanControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "menolak akses tanpa login" do
    get panduan_path
    assert_redirected_to new_user_session_path
  end

  test "merender markdown panduan sebagai HTML" do
    sign_in users(:budi)
    get panduan_path

    assert_response :success
    assert_select "h1", "Panduan Pengguna JEJAK Essential"
    assert_select "h2#daftar-isi"
  end

  # kramdown hanya mengenali tabel/fence bila didahului baris kosong; kalau
  # tidak, ia menjatuhkannya sebagai teks pipa mentah tanpa peringatan.
  test "tabel, diagram, dan blok kode tidak bocor sebagai teks mentah" do
    sign_in users(:budi)
    get panduan_path

    doc = Nokogiri::HTML5(response.body)
    body = doc.at_css(".markdown-body")
    assert_operator body.css("table").size, :>=, 10
    assert_operator body.css("svg.dg").size, :>=, 9
    assert_operator body.css("pre code").size, :>=, 2
    leaked = body.css("p").select { |p| p.text.include?("|---") || p.text.start_with?("~~~", "###") }
    assert_empty leaked, "teks mentah bocor: #{leaked.map(&:text).first(3)}"
  end

  test "setiap tautan anchor di panduan mengarah ke id yang ada" do
    sign_in users(:budi)
    get panduan_path

    doc = Nokogiri::HTML5(response.body)
    ids = doc.css("[id]").map { |el| el["id"] }
    anchors = doc.css(".markdown-body a[href^='#']").map { |a| a["href"].delete_prefix("#") }.uniq
    assert_operator anchors.size, :>, 60
    assert_empty anchors - ids, "anchor mati"
  end
end
