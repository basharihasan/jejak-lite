require "test_helper"

class AssessmentCohortProfileTest < ActiveSupport::TestCase
  setup do
    @event = assessment_events(:cbt_blok)
    @event.update!(allow_multiple_attempts: false)
    @siklus_dewasa = @event.assessment_dimensions.create!(name: "Siklus Kehidupan: Dewasa", max_score: 10)
    @siklus_anak = @event.assessment_dimensions.create!(name: "Siklus Kehidupan: Anak", max_score: 10)
    @proses = @event.assessment_dimensions.create!(name: "Penalaran Klinis", max_score: 50)

    @mine = assessment_instances(:siti_cbt_1)
    @mine.update!(score: 60)
    score(@mine, @siklus_dewasa => 6, @siklus_anak => 4, @proses => 30)
  end

  def score(instance, values)
    values.each { |dim, v| AssessmentDimensionScore.create!(assessment_instance: instance, assessment_dimension: dim, score: v) }
  end

  def add_student(name, total, dims)
    user = User.create!(full_name: name, email: "#{name.parameterize}@example.com", password: "password123", confirmed_at: Time.current)
    user.roles << roles(:mahasiswa)
    instance = AssessmentInstance.create!(assessment_event: @event, student: user, attempt_number: 1, status: "scored",
                                          source: "import", score: total, max_score: 100, scored_at: Time.current)
    score(instance, dims)
    instance
  end

  test "kohort kecil: posisi disembunyikan, radar hanya skor sendiri" do
    profile = AssessmentCohortProfile.new(@mine)
    assert_nil profile.position
    assert_equal [ "Siklus Kehidupan", "Semua Dimensi" ], profile.groups.map(&:name)
    assert_equal [ "Dewasa", "Anak" ], profile.groups.first.labels
    assert_equal [ 60.0, 40.0 ], profile.groups.first.mine
    assert_nil profile.groups.first.mean
  end

  test "kohort cukup: persentil, rerata, P90, dan pembanding per dimensi terisi" do
    add_student("Mhs Dua", 80, @siklus_dewasa => 8, @siklus_anak => 8, @proses => 40)
    add_student("Mhs Tiga", 40, @siklus_dewasa => 2, @siklus_anak => 4, @proses => 20)

    profile = AssessmentCohortProfile.new(@mine)
    pos = profile.position
    assert_equal 3, pos.cohort_size
    assert_equal 60.0, pos.my_percentage
    assert_equal 60.0, pos.mean
    assert_equal 50, pos.percentile
    assert_equal 76.0, pos.p90

    siklus = profile.groups.find { |g| g.name == "Siklus Kehidupan" }
    assert_equal [ (60 + 80 + 20) / 3.0, (40 + 80 + 40) / 3.0 ].map { |v| v.round(1) }, siklus.mean
    assert_equal 2, siklus.p90.size
  end

  test "percobaan tanpa nilai dimensi tidak punya grup" do
    AssessmentDimensionScore.where(assessment_instance: @mine).delete_all
    assert_empty AssessmentCohortProfile.new(@mine).groups
  end
end
