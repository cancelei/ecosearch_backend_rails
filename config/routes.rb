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
      resource controller: 'search' do
        collection do
          post :search
          get :search
        end
      end
    end
  end
end
