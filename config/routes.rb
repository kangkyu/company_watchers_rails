Rails.application.routes.draw do
  root "news_items#index"

  resources :news_items, only: [ :index, :destroy ]
  resources :companies, only: [ :index, :create, :update, :destroy ] do
    member do
      patch :toggle_pick
      post :sync_news
    end
  end

  namespace :admin do
    get "/", to: "dashboard#index"
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    post "sync_all", to: "sync#sync_all"
    post "search_and_import", to: "sync#search_and_import"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
