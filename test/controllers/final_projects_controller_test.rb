require "test_helper"

class FinalProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "mahasiswa lain tidak melihat tugas akhir orang lain di index" do
    other = User.create!(full_name: "Mahasiswa Lain", email: "fplain@example.com", password: "password123", confirmed_at: Time.current)
    other.roles << roles(:mahasiswa)

    sign_in other
    get final_projects_path

    assert_response :success
    assert_no_match final_projects(:skripsi_siti).title, response.body
  end

  test "dosen melihat semua tugas akhir (berpotensi jadi penguji)" do
    sign_in users(:budi)
    get final_projects_path

    assert_response :success
    assert_match final_projects(:skripsi_siti).title, response.body
  end

  test "mahasiswa mendaftarkan tugas akhir" do
    sign_in users(:siti)
    other = users(:siti)
    other.final_projects.destroy_all

    assert_difference "FinalProject.count", 1 do
      post final_projects_path, params: { final_project: { title: "Judul Baru" } }
    end
  end

  test "menambah milestone" do
    sign_in users(:siti)

    assert_difference "FinalProjectMilestone.count", 1 do
      post final_project_final_project_milestones_path(final_projects(:skripsi_siti)), params: {
        final_project_milestone: { title: "Ujian Hasil", target_date: 60.days.from_now.to_date }
      }
    end
  end

  test "dosen memberi skor ujian" do
    sign_in users(:budi)

    assert_difference "ExaminerScore.count", 1 do
      post final_project_examiner_scores_path(final_projects(:skripsi_siti)), params: {
        examiner_score: { session_date: Date.current, score: 90, feedback: "Sangat baik" }
      }
    end

    assert_equal users(:budi), ExaminerScore.order(:id).last.examiner
  end

  test "mahasiswa tidak bisa memberi skor ujian" do
    sign_in users(:siti)

    post final_project_examiner_scores_path(final_projects(:skripsi_siti)), params: {
      examiner_score: { session_date: Date.current, score: 90 }
    }

    assert_response :redirect
  end
end
