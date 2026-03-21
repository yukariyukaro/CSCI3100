Rails.application.routes.draw do
  root "home#index"

  resources :products, only: %i[index show]
  resources :chats, only: %i[index show]
  resources :payments, only: %i[index new show create]
  resources :listings, only: %i[index new create]
  resources :sessions, only: %i[new create destroy]
  resources :users, only: %i[index show]

  namespace :api do
    resources :products, only: %i[index show]
    resources :chats, only: %i[index show]
    resources :payments, only: %i[index create show]
    resources :listings, only: %i[index create show]
    resources :sessions, only: %i[create destroy]
    resources :users, only: %i[index show]
  end
end
