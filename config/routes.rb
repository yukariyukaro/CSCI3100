Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  get "/up", to: "rails/health#show"

  root "communities#root"

  get "/home", to: "home#index", as: :home
  post "/payments/webhook", to: "payments#webhook", as: :webhook_payments

  resources :communities, only: %i[index]
  scope "/:community_slug", as: "community" do
    resources :products, only: %i[index show] do
      get "autocomplete", on: :collection
      post "ask_ai_about_this", on: :member
      post "reserve", on: :member, to: "transactions#create"
      delete "cancel_reservation", on: :member, to: "transactions#destroy"
      patch "mark_sold", on: :member, to: "transactions#complete"
    end

    resources :conversations, only: %i[index show create] do
      resources :messages, only: %i[index create]
    end

    resources :payments, only: %i[index show] do
      get "fake", on: :member
      patch "resolve", on: :member
    end

    resources :transactions, only: [] do
      resources :payments, only: %i[create]
    end

    resources :listings, only: %i[index new create destroy]
  end

  resources :sessions, only: %i[new create destroy]
  resources :users, only: %i[index show new create update]

  namespace :api do
    scope "/:community_slug", as: "community" do
      resources :products, only: %i[index show] do
        get "ai_summary", on: :member
      end
      resources :chats, only: %i[index show]
      resources :payments, only: %i[index create show]
      resources :listings, only: %i[index create show] do
        post "price_suggestion", on: :collection
      end
    end
    resources :sessions, only: %i[create destroy]
    resources :users, only: %i[index show]
  end
end
