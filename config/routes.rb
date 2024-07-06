Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'sessions'
  }

  namespace :api do
    namespace :v1 do
      get 'csrf', to: 'csrf#index'
    end
  end
end
