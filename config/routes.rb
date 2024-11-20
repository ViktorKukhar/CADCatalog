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

  root 'home#index'
  get "up" => "rails/health#show", as: :rails_health_check
end
