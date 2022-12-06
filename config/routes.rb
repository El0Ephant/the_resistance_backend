Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index
  get 'user/:id', to: 'profile#account_info'
  get 'user/:id/stat', to: 'profile#stat'
  get 'user/:id/history', to: 'profile#matches_history'
end
