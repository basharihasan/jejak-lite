require "test_helper"

class ActivityLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:budi) }

  test "menolak akses tanpa login" do
    sign_out users(:budi)
    get activity_logs_path
    assert_redirected_to new_user_session_path
  end

  test "index hanya menampilkan kegiatan milik pengguna sendiri" do
    get activity_logs_path

    assert_response :success
    assert_match activity_logs(:jaga_igd).title, response.body
    assert_no_match activity_logs(:kegiatan_siti).title, response.body
  end

  test "filter kategori bekerja" do
    get activity_logs_path(category: "klinis")

    assert_match activity_logs(:jaga_igd).title, response.body
    assert_no_match activity_logs(:penyuluhan_stunting).title, response.body
  end

  test "mencatat kegiatan baru" do
    assert_difference "ActivityLog.count", 1 do
      post activity_logs_path, params: {
        activity_log: {
          title: "Skrining Gizi", category: "klinis", activity_type: "Skrining",
          activity_date: Date.current, description: "Skrining gizi balita."
        }
      }
    end

    log = ActivityLog.order(:id).last
    assert_redirected_to activity_log_path(log)
    assert_equal users(:budi), log.user
  end

  test "tidak bisa melihat kegiatan milik orang lain" do
    get activity_log_path(activity_logs(:kegiatan_siti))
    assert_response :not_found
  end

  test "generate_patient_code membuat kode untuk kegiatan klinis" do
    log = activity_logs(:jaga_igd)
    assert_nil log.patient_code

    post generate_patient_code_activity_log_path(log)

    assert_redirected_to activity_log_path(log)
    assert log.reload.patient_code.present?
  end

  test "mencatat kegiatan dengan tag kompetensi dan filter menampilkannya" do
    post activity_logs_path, params: {
      activity_log: {
        title: "Visite Ruangan", category: "klinis", activity_type: "Visite",
        activity_date: Date.current, competency_item_ids: [ competency_items(:domain_klinis).id ]
      }
    }
    log = ActivityLog.order(:id).last
    assert_equal [ competency_items(:domain_klinis) ], log.competency_items

    get activity_logs_path(competency_item_id: competency_items(:domain_klinis).id)
    assert_match log.title, response.body
    assert_no_match activity_logs(:penyuluhan_stunting).title, response.body
  end

  test "kalender mengelompokkan kegiatan per hari dalam bulan berjalan" do
    log = current_month_log
    get activity_logs_calendar_path

    assert_response :success
    assert_match log.title, response.body
  end

  test "feed iCal bisa diakses tanpa login lewat token" do
    sign_out users(:budi)
    token = users(:budi).calendar_feed_token!

    get activity_logs_feed_path(token: token)

    assert_response :success
    assert_match "BEGIN:VCALENDAR", response.body
    assert_equal "text/calendar", response.media_type
  end

  test "feed iCal menolak token yang salah" do
    get activity_logs_feed_path(token: "token-salah")
    assert_response :not_found
  end

  private

  def current_month_log
    users(:budi).activity_logs.create!(
      title: "Kegiatan Bulan Ini", category: "non_klinis", activity_date: Date.current
    )
  end
end
