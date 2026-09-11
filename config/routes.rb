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
