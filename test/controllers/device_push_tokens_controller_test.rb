require "test_helper"

class DevicePushTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "public_key terbuka tanpa login" do
    get vapid_public_key_path
    assert_response :success
  end

  test "menolak create tanpa login" do
    post device_push_token_path, params: { subscription: { endpoint: "https://push.example/x", keys: { p256dh: "a", auth: "b" } } }
    assert_response :redirect
  end

  test "menyimpan langganan push pengguna" do
    sign_in users(:budi)

    assert_difference "DevicePushToken.count", 1 do
      post device_push_token_path, params: {
        subscription: { endpoint: "https://push.example/abc", keys: { p256dh: "pkey", auth: "akey" } }
      }
    end

    assert_response :created
    assert_equal "https://push.example/abc", users(:budi).device_push_tokens.last.endpoint
  end

  test "subscribe dua kali dengan endpoint sama tidak menggandakan baris" do
    sign_in users(:budi)
    params = { subscription: { endpoint: "https://push.example/dup", keys: { p256dh: "p1", auth: "a1" } } }

    post device_push_token_path, params: params
    assert_no_difference "DevicePushToken.count" do
      post device_push_token_path, params: params
    end
  end

  test "destroy menghapus langganan berdasar endpoint" do
    sign_in users(:budi)
    token = users(:budi).device_push_tokens.create!(endpoint: "https://push.example/y", p256dh_key: "p", auth_key: "a")

    assert_difference "DevicePushToken.count", -1 do
      delete device_push_token_path, params: { endpoint: token.endpoint }
    end
  end
end
