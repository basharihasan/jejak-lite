Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  get "dashboard", to: "dashboard#show"
  resource :profile, only: %i[show edit update]
  resources :roles, only: [] do
    collection do
      patch :switch
    end
  end
  get "cari", to: "search#index", as: :search
  # Dasbor Mahasiswa (hanya-baca) untuk pengajar/kaprodi/admin — pintu masuk
  # dari hasil pencarian; kartunya membawa ?student_id= ke halaman asesmen.
  get "mahasiswa/:id", to: "student_dashboards#show", as: :student_dashboard
  get "panduan", to: "panduan#index", as: :panduan
  get "brand", to: "brand#index", as: :brand

  # Pengaturan Saya — tema & ukuran huruf (dipakai tombol tema topbar juga).
  get   "pengaturan",          to: "settings/preferences#edit",              as: :my_settings
  patch "pengaturan/tampilan", to: "settings/preferences#update_appearance", as: :update_appearance_settings
  patch "pengaturan/bahasa",   to: "settings/preferences#update_locale",     as: :update_locale_settings

  resources :notifications, only: %i[index] do
    member do
      patch :mark_as_read
      patch :archive
    end
    collection do
      patch :mark_all_read
    end
  end
  resource :device_push_token, only: %i[create destroy]
  get "vapid_public_key", to: "device_push_tokens#public_key"

  resources :activity_logs do
    member do
      post :generate_patient_code
      patch :verify
    end
  end
  get "kalender", to: "activity_logs#calendar", as: :activity_logs_calendar
  get "kalender/feed/:token", to: "activity_logs#feed", as: :activity_logs_feed
  post "kalender/token/reset", to: "activity_logs#reset_feed_token", as: :reset_calendar_feed_token

  resource :portfolio, only: %i[show]
  get "portfolio/export", to: "portfolios#export", as: :export_portfolio

  resources :clinical_cases do
    member do
      patch :submit
      patch :verify
      patch :request_revision
      patch :reject
      patch :cancel_verification
      post  :comment
      post  :break_glass
      post  :issue_consent
      patch :revoke_consent
      post  :initiate_assessment   # CBD / Long Case dari kasus
      post  :initiate_workplace_assessment # Mini-CEX / DOPS dari kasus
    end
  end
  # Lembar persetujuan pasien — publik, tanpa login, bertoken 32 karakter.
  get   "persetujuan/:token", to: "public/patient_consents#show",   as: :public_patient_consent
  patch "persetujuan/:token", to: "public/patient_consents#update"

  resources :clinical_rotations, except: %i[show]
  # Enrolment Tutorial (PSSK) — padanan rotasi klinik untuk blok/sistem.
  resources :tutorial_enrollments, except: %i[show] do
    member { patch :toggle_active }
  end
  resources :academic_periods, except: %i[show]
  resources :study_programs, only: %i[index new create edit update]

  namespace :admin do
    resource :data_governance, only: %i[show update], controller: "data_governance"
    resources :diagnosis_definitions, except: %i[show] do
      collection { post :import }
    end
    resources :skill_definitions, except: %i[show] do
      collection { post :import }
    end
    resources :medication_definitions, except: %i[show] do
      collection { post :import }
    end
    resources :logbook_case_targets, except: %i[show]
    # Domain Kegiatan Akademik (taksonomi Logbook Kegiatan & Kalender) dan
    # Taksonomi Istilah — padanan menu Konfigurasi jejak.pro.
    concern :taxonomy_node do
      member do
        patch :move
        patch :toggle_active
      end
    end
    resources :academic_activity_domains, except: %i[show], concerns: :taxonomy_node do
      resources :academic_activity_subdomains, only: %i[new create edit update destroy], shallow: true,
                                               concerns: :taxonomy_node do
        resources :academic_activity_templates, only: %i[new create edit update destroy], shallow: true,
                                                concerns: :taxonomy_node
      end
    end
    get   "terminology", to: "terminology_overrides#index", as: :terminology
    patch "terminology", to: "terminology_overrides#update"
    resources :assessment_events do
      member do
        get  :import
        get  :import_template
        post :import_preview
        post :import_create
        post :add_instance
      end
      resources :assessment_instances, only: %i[update destroy], shallow: true
      resources :assessment_dimensions, only: %i[create update destroy], shallow: true do
        collection { patch :bulk_map }
      end
    end
    # Unggah CSV hasil CBT & OSCE berformat ekspor Glide (berkas .csv, bukan
    # API Glide) — padanan /admin/glide_syncs/csv_import dan /admin/cbt_exams
    # jejak.pro. Indeks glide_syncs = riwayat unggahan + rollback.
    resources :glide_syncs, only: %i[index show], constraints: { id: /\d+/ } do
      collection do
        get  :csv_import
        post :csv_import, action: :process_csv_import
        get  :template
      end
      member { post :rollback }
    end
    resources :cbt_exams, only: %i[index edit update destroy]
    resources :evaluation_schedules, except: %i[show]
    resources :learning_units do
      member do
        post   :add_mapping
        delete "mapping/:mapping_id", action: :remove_mapping, as: :remove_mapping
      end
    end
    resources :users, only: %i[index edit update] do
      member do
        patch :reset_password
        patch :confirm_email
      end
      collection do
        get  :import
        post :import, action: :import_create
      end
    end
    # Relabel massal prodi mahasiswa dari CSV (pindah / label ke prodi saya) —
    # padanan /management/student_relabel jejak.pro. Pratinjau dulu, lalu terapkan.
    resource :student_relabel, only: %i[new create] do
      get :template, on: :collection
    end
    # Pusat Ekspor Data (CSV) — admin & kaprodi; :id = kunci dataset DataExport.
    resources :exports, only: %i[index show]
  end

  resources :reflection_entries

  resources :dops_evaluations, except: %i[index] do
    member { patch :submit }
  end
  resources :mini_cex_evaluations, except: %i[index] do
    member { patch :submit }
  end
  get "asesmen", to: "assessments#index", as: :assessments

  resources :assessment_form_templates do
    resources :assessment_form_fields, only: %i[new create edit update destroy] do
      member do
        patch :move_up
        patch :move_down
      end
    end
    resources :assessment_form_submissions, only: %i[new create], shallow: true
  end
  resources :assessment_form_submissions, only: %i[index show]

  resources :final_projects do
    resources :final_project_milestones, only: %i[new create destroy], shallow: true do
      member { patch :toggle }
    end
    resources :examiner_scores, only: %i[new create], shallow: true
  end

  # Fase 25 — Pilar B: Evaluasi Akademik (nilai per tipe), asesmen berbasis
  # rubrik/dokumen untuk mahasiswa, lembar penilai untuk penguji, jurnal umpan
  # balik penguji.
  get "nilai-ujian", to: "academic_scores#index", as: :exam_scores
  namespace :student do
    resources :assessments, only: %i[index show] do
      member { patch :submit }
    end
    resources :assessment_events, only: [] do
      member { post :register }
    end
    get "feedback_journal", to: "feedback_journal#index"
  end
  resources :examiner_evaluations, only: %i[index show update]
  # Peta EPA & Tingkat Entrustment (jejak.pro: /dashboard/entrustment)
  get  "dashboard/entrustment", to: "entrustment_decisions#index",  as: :entrustment_decisions
  post "dashboard/entrustment", to: "entrustment_decisions#create"

  resources :assessment_blueprints do
    resources :assessment_blueprint_mappings, only: %i[create destroy]
  end
  resources :competency_frameworks do
    resources :competency_items, only: %i[create destroy]
  end
  resources :competency_items, only: [] do
    resources :competency_milestones, only: %i[create destroy]
  end
  get "capaian-belajar", to: "academic_assessments#index", as: :academic_assessments
  get "analitik", to: "analytics#index", as: :analytics

  # Service worker perlu di-root (bukan /assets) supaya scope-nya mencakup
  # seluruh situs — syarat Push API.
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: "js" }
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: "json" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end
  root to: "home#index"
end
