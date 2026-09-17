# frozen_string_literal: true

# Data demo untuk mencoba SEMUA fitur jejak-lite tanpa mendaftar manual —
# terpisah dari db/seeds.rb (yang cuma berisi data rujukan wajib: peran,
# prodi, templat formulir baku) karena ini akun & data CONTOH dengan
# password lemah yang diketahui publik, bukan data rujukan aplikasi.
# Idempoten: aman dijalankan berkali-kali (find_or_create_by! di semua titik).
namespace :demo do
  desc "Buat akun & data demo untuk mencoba semua fitur jejak-lite (password: DEMO_PASSWORD, bawaan password123)"
  task seed: :environment do
    # Instance publik wajib menimpa lewat DEMO_PASSWORD; bawaannya sengaja
    # lemah supaya mencoba di komputer sendiri tetap sederhana.
    demo_password = (ENV["DEMO_PASSWORD"].presence || "password123")
    if Rails.env.production?
      puts "Peringatan: menjalankan data DEMO di production."
      puts "Hanya lakukan ini untuk instance demo/showcase, bukan deployment sungguhan."
    end

    def demo_user(email, full_name:, roles:, study_program: nil, password: (ENV["DEMO_PASSWORD"].presence || "password123"))
      user = User.find_or_initialize_by(email: email)
      user.full_name = full_name
      user.study_program = study_program if study_program
      # Kata sandi disetel ulang bila berbeda, supaya DEMO_PASSWORD yang
      # diganti belakangan ikut berlaku ke akun demo yang sudah ada (dulu
      # hanya akun baru yang kena, akun lama tetap memakai sandi lama).
      unless !user.new_record? && user.valid_password?(password)
        user.password = user.password_confirmation = password
      end
      user.confirmed_at ||= Time.current
      user.save!(validate: false)

      roles.each do |code|
        role = Role.find_by!(code: code)
        user.roles << role unless user.has_role?(code)
      end
      user.update!(active_role: user.roles.find_by(code: roles.first)) if user.active_role.nil?
      user
    end

    sarjana = StudyProgram.find_or_create_by!(name: "Sarjana Kedokteran")
    profesi = StudyProgram.find_or_create_by!(name: "Profesi Dokter")

    admin = demo_user("admin.demo@jejaklite.test", full_name: "Admin Demo", roles: %w[admin])
    dosen = demo_user("dosen.demo@jejaklite.test", full_name: "Dosen Demo", roles: %w[dosen])
    preseptor = demo_user("preseptor.demo@jejaklite.test", full_name: "Preseptor Demo", roles: %w[preseptor])
    kaprodi = demo_user("kaprodi.demo@jejaklite.test", full_name: "Kaprodi Demo", roles: %w[kaprodi], study_program: sarjana)
    multirole = demo_user("multirole.demo@jejaklite.test", full_name: "Multi Peran Demo", roles: %w[mahasiswa dosen], study_program: profesi)
    mahasiswa1 = demo_user("mahasiswa1.demo@jejaklite.test", full_name: "Andi Mahasiswa", roles: %w[mahasiswa], study_program: sarjana)
    mahasiswa2 = demo_user("mahasiswa2.demo@jejaklite.test", full_name: "Citra Mahasiswa", roles: %w[mahasiswa], study_program: sarjana)

    period = AcademicPeriod.find_or_create_by!(name: "2026/2027 Ganjil") do |p|
      p.start_date = 1.month.ago.to_date
      p.end_date = 5.months.from_now.to_date
    end

    rotation1 = ClinicalRotation.find_or_create_by!(user: mahasiswa1, academic_period: period, station_name: "Ilmu Penyakit Dalam") do |r|
      r.preceptor = preseptor
      r.institution_name = "RSUP Demo"
      r.start_date = 3.days.ago.to_date
      r.end_date = 11.days.from_now.to_date
    end
    ClinicalRotation.find_or_create_by!(user: mahasiswa2, academic_period: period, station_name: "Ilmu Kesehatan Anak") do |r|
      r.preceptor = preseptor
      r.institution_name = "Puskesmas Demo"
      r.start_date = 1.day.ago.to_date
      r.end_date = 13.days.from_now.to_date
    end

    klinis_domain = CompetencyItem.find_by(title: "Keterampilan Klinis")

    AcademicActivityTaxonomySeeder.call
    # Pasangan (domain, subdomain) taksonomi bawaan; nil bila admin sudah
    # mengubah namanya — kegiatan demo tetap dibuat, hanya tanpa taksonomi.
    demo_kinds = [ [ "Praktek", "Stase Ruang perawatan" ], [ "Belajar Mengajar", "Bed-site Teaching" ] ].map do |domain_name, subdomain_name|
      AcademicActivitySubdomain.joins(:academic_activity_domain)
                               .find_by(name: subdomain_name, academic_activity_domains: { name: domain_name })
    end

    [ mahasiswa1, mahasiswa2 ].each_with_index do |student, i|
      log = ActivityLog.find_or_create_by!(user: student, title: "Kegiatan Logbook Demo #{i + 1}") do |l|
        l.category = "klinis"
        l.academic_activity_subdomain = demo_kinds[i]
        l.started_at = (i + 1).days.ago.change(hour: 8)
        l.ended_at = (i + 1).days.ago.change(hour: 12)
        l.activity_date = (i + 1).days.ago.to_date
        l.location = "RSUP Demo"
        l.delivery_mode = "luring"
        l.description = "Contoh entri logbook untuk demo."
      end
      log.competency_items = [ klinis_domain ].compact if klinis_domain && log.competency_items.empty?
    end

    verified_case = ClinicalCase.find_or_create_by!(user: mahasiswa1, chief_complaint: "Demam 3 hari") do |c|
      c.case_date = 5.days.ago.to_date
      c.clinical_setting = "rawat_jalan"
      c.case_complexity = "sedang"
      c.patient_age_group = "Dewasa"
      c.patient_gender = "Perempuan"
      c.anamnesis = "Demam naik-turun sejak 3 hari, disertai nyeri kepala dan mual. Riwayat bepergian ke luar kota 1 minggu lalu."
      c.general_condition = "Tampak sakit sedang, kompos mentis, tidak sesak."
      c.physical_examination = "Lidah kotor tepi hiperemis, nyeri tekan epigastrium ringan, hepar/lien tidak teraba membesar."
      c.family_history = "Tidak ada riwayat penyakit serupa di keluarga."
      c.vital_signs = { "temperature" => 38.6, "bp_systolic" => 110, "bp_diastolic" => 70, "pulse" => 88, "respiratory_rate" => 20, "weight_kg" => 58, "height_cm" => 160 }
      c.diagnosis = "Demam tifoid"
      c.management = "Antibiotik lini pertama + edukasi"
      c.learning_points = "Pentingnya anamnesis riwayat bepergian."
      c.status = "verified"
      c.verified_by = dosen
      c.verified_at = 4.days.ago
      c.entrustment_level = "supervisi_tidak_langsung"
    end
    verified_case.case_verification_comments.find_or_create_by!(action: "verified") do |comment|
      comment.user = dosen
      comment.body = "Anamnesis lengkap, pertahankan."
    end
    ClinicalCase.find_or_create_by!(user: mahasiswa2, chief_complaint: "Nyeri perut akut") do |c|
      c.case_date = 1.day.ago.to_date
      c.clinical_setting = "igd"
      c.case_complexity = "rendah"
      c.patient_age_group = "Anak"
      c.patient_gender = "Laki-laki"
      c.diagnosis = "Gastroenteritis akut"
      c.management = "Rehidrasi oral"
      c.learning_points = "Tanda dehidrasi pada anak."
      c.status = "submitted"
    end

    DopsEvaluation.find_or_create_by!(student: mahasiswa1, evaluator: dosen, clinical_rotation: rotation1, procedure_name: "Pemasangan Infus (Demo)") do |d|
      d.evaluated_at = 2.days.ago.to_date
      d.clinical_setting = "rawat_inap"
      d.patient_age_group = "dewasa"
      d.case_complexity = "sedang"
      d.observation_minutes = 15
      d.feedback_minutes = 5
      d.scores = {
        "persetujuan_tindakan" => 8, "persiapan" => 7, "analgesia_sedasi" => 7, "kemampuan_teknis" => 7,
        "asepsis" => 8, "meminta_bantuan" => 7, "pasca_tindakan" => 7, "komunikasi" => 7,
        "profesionalisme" => 8, "penilaian_global" => 7
      }
      d.overall_feedback = "Baik, pertahankan kehati-hatian asepsis."
    end
    MiniCexEvaluation.find_or_create_by!(student: mahasiswa1, evaluator: preseptor, clinical_rotation: rotation1, case_description: "Anamnesis Nyeri Dada (Demo)") do |m|
      m.evaluated_at = 1.day.ago.to_date
      m.clinical_setting = "igd"
      m.patient_age_group = "dewasa"
      m.case_complexity = "sedang"
      m.global_rating = "performed"
      m.scores = { "anamnesis" => 7, "profesionalisme" => 8, "clinical_judgment" => 6, "komunikasi" => 7, "organisasi" => 7, "pemeriksaan_fisik" => 7 }
    end

    final_project = FinalProject.find_or_create_by!(student: mahasiswa1, title: "Skripsi Demo: Faktor Risiko Hipertensi") do |f|
      f.supervisor = dosen
      f.description = "Contoh tugas akhir untuk demo."
      f.status = "ongoing"
    end
    final_project.final_project_milestones.find_or_create_by!(title: "Seminar Proposal") do |m|
      m.target_date = 10.days.ago.to_date
      m.completed_at = 8.days.ago
    end
    final_project.final_project_milestones.find_or_create_by!(title: "Sidang Akhir") do |m|
      m.target_date = 30.days.from_now.to_date
    end

    template = AssessmentFormTemplate.find_by(name: "Evaluasi Blok")
    if template && AssessmentFormSubmission.find_by(respondent: mahasiswa1, assessment_form_template: template).nil?
      # Jawaban dirakit dulu lalu disimpan sekali: validasi
      # all_required_fields_answered berjalan saat create, jadi submission
      # kosong selalu ditolak pada basis data bersih.
      submission = template.assessment_form_submissions.new(respondent: mahasiswa1, submitted_at: Time.current)
      template.assessment_form_fields.each do |field|
        value = case field.field_type
        when "rating" then "4"
        when "yes_no" then "Tidak"
        else "Contoh jawaban demo."
        end
        submission.assessment_form_answers.new(assessment_form_field: field, value: value)
      end
      submission.save!
    end

    # Fase 25 — Assessment Event & percobaan (menggantikan ExamImport/ExamScore).
    cbt_event = AssessmentEvent.find_or_create_by!(name: "CBT Blok Demo", assessment_type: "cbt", academic_period: period) do |e|
      e.study_program = sarjana
      e.exam_date = 6.days.ago.to_date
      e.status = "published"
      e.created_by = admin
    end
    { mahasiswa1 => 82, mahasiswa2 => 74 }.each do |student, score|
      AssessmentInstance.find_or_create_by!(assessment_event: cbt_event, student: student, attempt_number: 1) do |i|
        i.score = score
        i.max_score = 100
        i.status = "scored"
        i.source = "import"
        i.scored_at = 6.days.ago
      end
    end
    soca_event = AssessmentEvent.find_or_create_by!(name: "SOCA Sistem Kardiovaskular", assessment_type: "soca_msp", academic_period: period) do |e|
      e.study_program = sarjana
      e.block_name = "Sistem Kardiovaskular"
      e.exam_date = 3.days.from_now.to_date
      e.status = "published"
      e.submission_close_at = 7.days.from_now
      e.created_by = admin
    end
    TutorialEnrollment.find_or_create_by!(user: mahasiswa1, academic_period: period, block_name: "Sistem Kardiovaskular") do |te|
      te.tutor = dosen
      te.group_name = "Kelompok 1"
      te.active = true
    end
    AssessmentInstance.find_or_create_by!(assessment_event: soca_event, student: mahasiswa1, attempt_number: 1) do |i|
      i.examiner = dosen
      i.status = "submitted"
      i.submitted_at = 1.day.ago
      i.self_evaluation = "Saya sudah memahami patofisiologi gagal jantung, masih perlu latihan menyusun rencana tatalaksana."
    end

    ReflectionEntry.find_or_create_by!(user: mahasiswa1, entry_date: 2.days.ago.to_date) do |r|
      r.content = "Refleksi demo: belajar pentingnya komunikasi empatik dengan pasien."
    end

    # Sandi kustom tidak dicetak supaya tidak tertinggal di log build Render.
    shown_password = ENV["DEMO_PASSWORD"].present? ? "sesuai DEMO_PASSWORD" : demo_password
    puts "Data demo siap. Akun (password: #{shown_password}):"
    [ admin, dosen, preseptor, kaprodi, multirole, mahasiswa1, mahasiswa2 ].each do |u|
      puts "  #{u.email.ljust(32)} #{u.roles.pluck(:code).join(', ')}"
    end
  end
end
