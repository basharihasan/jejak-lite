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

  test "tidak bisa menautkan kegiatan atau kasus milik mahasiswa lain" do
    assert_no_difference "ReflectionEntry.count" do
      post reflection_entries_path, params: {
        reflection_entry: { entry_date: Date.current, content: "Coba tautan orang lain.", activity_log_id: activity_logs(:jaga_igd).id }
      }
    end
    assert_response :unprocessable_entity
    assert_match "bukan kegiatan milik Anda", response.body
  end

  test "kegiatan dan draf kasus yang ditautkan refleksi tetap bisa dihapus; refleksinya tetap ada" do
    entry = ReflectionEntry.create!(user: users(:siti), entry_date: Date.current, content: "Tertaut.",
                                    activity_log: activity_logs(:kegiatan_siti), clinical_case: clinical_cases(:draft_case_siti))

    assert_difference "ActivityLog.count", -1 do
      delete activity_log_path(activity_logs(:kegiatan_siti))
    end
    assert_difference "ClinicalCase.count", -1 do
      delete clinical_case_path(clinical_cases(:draft_case_siti))
    end
    entry.reload
    assert_nil entry.activity_log_id
    assert_nil entry.clinical_case_id
  end
end
