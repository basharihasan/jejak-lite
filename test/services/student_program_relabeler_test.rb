require "test_helper"

class StudentProgramRelabelerTest < ActiveSupport::TestCase
  setup do
    @pssk = study_programs(:sarjana_kedokteran)
    @pspd = study_programs(:profesi_dokter)
  end

  def create_student(email, program: @pssk, npm: nil, cohort: nil)
    user = User.create!(full_name: email.split("@").first.capitalize, email: email, password: "password123",
                        confirmed_at: Time.current, study_program: program,
                        identifier_number: npm, cohort_year: cohort)
    user.roles << roles(:mahasiswa)
    user
  end

  def relabeler(csv, **options)
    StudentProgramRelabeler.new(csv: csv, mode: "pindah", target_study_program: @pspd, **options)
  end

  def note_for(matches, identifier)
    matches.find { |m| m.identifier == identifier }.note
  end

  test "mencocokkan lewat email atau NPM lama dan mengganti prodi, NPM, serta angkatan" do
    ani = create_student("ani@example.com", npm: "2206001", cohort: 2022)
    csv = <<~CSV
      email,npm,angkatan
      SITI@example.com,,
      2206001,1306001,2026
    CSV

    result = relabeler(csv).apply!

    assert_equal 2, result.updated
    assert_equal 0, result.skipped
    assert_equal @pspd, users(:siti).reload.study_program
    ani.reload
    assert_equal @pspd, ani.study_program
    assert_equal "1306001", ani.identifier_number
    assert_equal 2026, ani.cohort_year
  end

  test "pratinjau tidak menyimpan apa pun" do
    matches = relabeler("email\nsiti@example.com\n").matches

    assert_equal [ "siap" ], matches.map(&:note)
    assert_equal @pssk, users(:siti).reload.study_program
  end

  test "baris bermasalah dilewati dengan catatan, bukan menggagalkan batch" do
    create_student("kembar1@example.com", npm: "2206777")
    create_student("kembar2@example.com", npm: "2206777")
    create_student("ani@example.com")
    create_student("budi.m@example.com")
    create_student("cici@example.com")
    create_student("pemilik@example.com", npm: "1306999")
    create_student("sudah@example.com", program: @pspd)
    csv = <<~CSV
      email,npm,angkatan
      hantu@example.com,,
      2206777,,
      budi@example.com,,
      ani@example.com,1306100,
      budi.m@example.com,1306100,
      cici@example.com,1306999,
      siti@example.com,,20xx
      sudah@example.com,,
    CSV

    matches = relabeler(csv).matches

    assert_equal "tidak ditemukan", note_for(matches, "hantu@example.com")
    assert_equal "NPM ini dipakai 2 akun — gunakan email", note_for(matches, "2206777")
    assert_equal "bukan akun mahasiswa — dilewati", note_for(matches, "budi@example.com")
    assert_equal "NPM baru dobel di CSV ini — dilewati", note_for(matches, "ani@example.com")
    assert_equal "NPM baru dobel di CSV ini — dilewati", note_for(matches, "budi.m@example.com")
    assert_equal "NPM baru sudah dipakai akun lain — dilewati", note_for(matches, "cici@example.com")
    assert_match "angkatan '20xx' tidak terbaca", note_for(matches, "siti@example.com")
    assert_equal "sudah sesuai — tidak ada perubahan", note_for(matches, "sudah@example.com")
    assert_equal [ 2, 3, 4, 5, 6, 7, 8, 9 ], matches.map(&:line)
    assert matches.none?(&:eligible?)
  end

  test "akun yang muncul dua kali (email dan NPM) dilewati keduanya" do
    create_student("ani@example.com", npm: "2206001")
    matches = relabeler("email\nani@example.com\n2206001\n").matches

    assert_equal [ "akun yang sama muncul 2× di CSV — dilewati" ] * 2, matches.map(&:note)
  end

  test "restrict_to_study_program_id menolak mahasiswa prodi lain" do
    create_student("pspd@example.com", program: @pspd)
    matches = StudentProgramRelabeler.new(csv: "email\npspd@example.com\nsiti@example.com\n", mode: "pindah",
                                          target_study_program: @pssk,
                                          restrict_to_study_program_id: @pssk.id).matches

    assert_equal "di luar prodi Anda — dilewati", note_for(matches, "pspd@example.com")
    # Siti sudah di PSSK dan tidak ada perubahan NPM/angkatan.
    assert_equal "sudah sesuai — tidak ada perubahan", note_for(matches, "siti@example.com")
  end

  test "angkatan default dipakai hanya untuk baris yang kolom angkatannya kosong" do
    ani = create_student("ani@example.com", cohort: 2020)
    csv = "email;angkatan\nsiti@example.com;\nani@example.com;2025.0\n"

    relabeler(csv, default_cohort_year: "2026").apply!

    assert_equal 2026, users(:siti).reload.cohort_year
    assert_equal 2025, ani.reload.cohort_year
  end

  test "angkatan default yang tidak valid ditolak" do
    error = assert_raises(StudentProgramRelabeler::Error) { relabeler("email\nsiti@example.com\n", default_cohort_year: "abc") }
    assert_match "Angkatan default", error.message
  end

  test "BOM Excel dan pemisah titik koma dibaca" do
    matches = relabeler("\xEF\xBB\xBFEmail;NPM Baru\nsiti@example.com;1306555\n".b).matches

    assert_equal [ "siap" ], matches.map(&:note)
    assert_equal "1306555", matches.first.new_npm
  end

  test "akun yang datanya tidak lolos validasi ketahuan di pratinjau" do
    users(:siti).update_column(:phone, "telp: 0812")
    match = relabeler("email\nsiti@example.com\n").matches.first

    refute match.eligible?
    assert_match "data akun tidak valid", match.note
    # Pratinjau mengembalikan atribut yang sempat diubah untuk validasi.
    assert_equal @pssk.id, match.user.study_program_id
  end

  test "tanpa kolom email ditolak dengan pesan jelas" do
    error = assert_raises(StudentProgramRelabeler::Error) { relabeler("nama,npm\nSiti,1\n").matches }
    assert_match "Kolom 'email'", error.message
  end

  test "lebih dari batas baris ditolak, bukan dipotong diam-diam" do
    csv = "email\n" + Array.new(StudentProgramRelabeler::MAX_ROWS + 1) { |i| "m#{i}@example.com" }.join("\n")
    error = assert_raises(StudentProgramRelabeler::Error) { relabeler(csv).matches }
    assert_match "maksimal #{StudentProgramRelabeler::MAX_ROWS}", error.message
  end

  test "aksi dan prodi tujuan wajib valid" do
    assert_raises(StudentProgramRelabeler::Error) do
      StudentProgramRelabeler.new(csv: "", mode: "lulus", target_study_program: @pspd)
    end
    assert_raises(StudentProgramRelabeler::Error) do
      StudentProgramRelabeler.new(csv: "", mode: "pindah", target_study_program: nil)
    end
  end
end
