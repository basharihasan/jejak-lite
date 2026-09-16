require "test_helper"

# Berkas PWA dilayani di root supaya scope service worker mencakup seluruh
# situs. Rails::PwaController merender templat menurut format permintaan,
# sehingga tanpa format bawaan di rute, membuka URL ini langsung di tab
# (Accept: text/html) meledak walau pemasangan PWA lewat browser tetap jalan.
class PwaEndpointsTest < ActionDispatch::IntegrationTest
  test "manifest terlayani untuk Accept apa pun" do
    [ "*/*", "text/html" ].each do |accept|
      get pwa_manifest_path, headers: { "Accept" => accept }
      assert_response :success, "manifest gagal untuk Accept: #{accept}"
      assert_match "JEJAK", response.body
    end
  end

  test "service worker terlayani untuk Accept apa pun" do
    [ "*/*", "text/html" ].each do |accept|
      get pwa_service_worker_path, headers: { "Accept" => accept }
      assert_response :success, "service worker gagal untuk Accept: #{accept}"
    end
  end
end
