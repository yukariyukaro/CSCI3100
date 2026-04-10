Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  root "products#index"

  get "/home", to: "home#index", as: :home

  resources :products, only: %i[index show] do
    get "autocomplete", on: :collection
    post "reserve", on: :member, to: "transactions#create"
    delete "cancel_reservation", on: :member, to: "transactions#destroy"
    patch "mark_sold", on: :member, to: "transactions#complete"
  end
  get "/chats", to: redirect("/conversations", status: 301)
  get "/chats/:id", to: redirect("/conversations/%{id}", status: 301)
  resources :conversations, only: %i[index show create] do
    resources :messages, only: %i[index create]
  end
  resources :payments, only: %i[index new show create]
  resources :listings, only: %i[index new create]
  resources :sessions, only: %i[new create destroy]
  resources :users, only: %i[index show new create update]

  namespace :api do
    resources :products, only: %i[index show]
    resources :chats, only: %i[index show]
    resources :payments, only: %i[index create show]
    resources :listings, only: %i[index create show]
    resources :sessions, only: %i[create destroy]
    resources :users, only: %i[index show]
  end
end
