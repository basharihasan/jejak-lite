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
  get "panduan", to: "panduan#index", as: :panduan
  get "brand", to: "brand#index", as: :brand

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
    end
  end

  resources :clinical_rotations, except: %i[show]
  resources :academic_periods, except: %i[show]

  resources :reflection_entries

  resources :dops_evaluations, except: %i[index]
  resources :mini_cex_evaluations, except: %i[index]
  get "asesmen", to: "assessments#index", as: :assessments

  resources :assessment_form_templates do
    resources :assessment_form_fields, only: %i[new create edit update destroy]
    resources :assessment_form_submissions, only: %i[new create], shallow: true
  end
  resources :assessment_form_submissions, only: %i[index show]

  # Service worker perlu di-root (bukan /assets) supaya scope-nya mencakup
  # seluruh situs — syarat Push API.
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end
  root to: "home#index"
end
