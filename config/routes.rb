Rails.application.routes.draw do
  scope 'api' do
    devise_for :users,
               defaults: { format: :json }, # to avoid "undefined local variable or method `flash' for"
               path: '',
               path_names: {
                 sign_in: 'sign_in',
                 sign_out: 'sign_out',
                 registration: 'sign_up'
               },
               controllers: {
                 sessions: 'users/sessions',
                 registrations: 'users/registrations'
               }
    get 'member-data', to: 'members#show'

    get 'user/:id', to: 'profile#account_info'
    get 'user/:id/stat', to: 'profile#stat'
    get 'user/:id/history', to: 'profile#games_history'
  end
end
