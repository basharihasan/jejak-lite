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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end
  root to: "home#index"
end
