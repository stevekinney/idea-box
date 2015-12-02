Rails.application.routes.draw do
  root to: 'static#main'

  namespace :api do
    namespace :v1 do
      resources :ideas
    end
  end

end
