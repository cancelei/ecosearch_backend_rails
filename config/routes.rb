Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'sessions',
    registrations: 'registrations',
    passwords: 'passwords',
    confirmations: 'confirmations',
    unlocks: 'unlocks'
  }

  resources :users, only: [:index, :show, :update, :destroy]

  namespace :api do
    namespace :v1 do
      get 'csrf', to: 'csrf#index'

      resources :search, only: [:index] do
        collection do
          get 'results'
          post 'index'
        end
      end
    end
  end
end
