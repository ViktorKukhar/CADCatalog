Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  resources :records do
    member do
      get :download_all_files
    end
  end

  namespace :users do
    resource :profile
  end

  # Reports and analytics routes
  namespace :reports do
    get :dashboard, on: :collection
    get :records_analysis, on: :collection
    get :software_analysis, on: :collection
    get :tags_analysis, on: :collection
    get :user_analysis, on: :collection
    get :complexity_analysis, on: :collection
    get :timeline_analysis, on: :collection
    post :export_csv, on: :collection
  end

  root 'home#index'
  get "up" => "rails/health#show", as: :rails_health_check
end
