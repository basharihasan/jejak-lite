require "test_helper"

class ReflectionEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:siti) }

  test "menolak akses tanpa login" do
    sign_out users(:siti)
    get reflection_entries_path
    assert_redirected_to new_user_session_path
  end

  test "index hanya menampilkan refleksi milik sendiri" do
    other = User.create!(full_name: "Lain", email: "reflect.lain@example.com", password: "password123", confirmed_at: Time.current)
    other_entry = ReflectionEntry.create!(user: other, entry_date: Date.current, content: "Punya orang lain")

    get reflection_entries_path

    assert_response :success
    assert_match reflection_entries(:refleksi_siti).title, response.body
    assert_no_match other_entry.content, response.body
  end

  test "tidak bisa melihat refleksi milik orang lain" do
    other = User.create!(full_name: "Lain", email: "reflect.lain2@example.com", password: "password123", confirmed_at: Time.current)
    other_entry = ReflectionEntry.create!(user: other, entry_date: Date.current, content: "Punya orang lain")

    get reflection_entry_path(other_entry)
    assert_response :not_found
  end

  test "membuat refleksi baru, opsional tertaut ke kegiatan" do
    assert_difference "ReflectionEntry.count", 1 do
      post reflection_entries_path, params: {
        reflection_entry: { entry_date: Date.current, content: "Belajar banyak hari ini.", activity_log_id: activity_logs(:kegiatan_siti).id }
      }
    end

    entry = ReflectionEntry.order(:id).last
    assert_equal activity_logs(:kegiatan_siti), entry.activity_log
    assert_redirected_to reflection_entry_path(entry)
  end
end
