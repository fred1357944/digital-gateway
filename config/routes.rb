Rails.application.routes.draw do
  # Devise authentication
  devise_for :users

  # Root
  root "home#index"

  # User settings
  resource :settings, only: %i[show update]

  # Public products
  resources :products, only: %i[index show]

  # Smart commerce features
  resources :compare, only: %i[index show] do
    collection do
      get :pareto
    end
  end

  # AI 智慧功能
  namespace :ai do
    get "search", to: "search#index"

    resources :products, only: [] do
      resource :preview, only: :create
      resource :decision, only: :create
    end
  end

  # Orders (buyer)
  resources :orders, only: %i[index show create] do
    member do
      get :download
    end
  end

  # Seller namespace
  namespace :seller do
    resources :products do
      member do
        post :submit_review
      end
    end
    resource :profile, only: %i[show edit update]
  end

  # API namespace
  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show]
      resources :orders, only: %i[create show index]

      # Buyer endpoints
      namespace :buyer do
        resources :orders, only: %i[index show]
        get "access/:token", to: "access#show", as: :access
      end

      # Seller endpoints
      namespace :seller do
        resources :products
        resources :orders, only: :index
      end
    end
  end

  # ECPay webhook
  namespace :webhooks do
    post "ecpay/notify", to: "ecpay#notify"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
