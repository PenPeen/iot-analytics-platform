Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Dashboard page - serve ERB file
  get '/', to: 'dashboard#index'
  get '/dashboard', to: 'dashboard#show'

  # Dashboard JSON API endpoints
  get '/api/dashboard', to: 'dashboard#show'
  get '/api/dashboard/realtime', to: 'dashboard#realtime'
  get '/api/dashboard/statistics', to: 'dashboard#statistics'

  # Device management routes
  resources :devices, only: [:index, :show, :create, :update, :destroy] do
    member do
      patch :update_status
      get :sensor_data
    end

    collection do
      get :active
      get :by_type
      post :bulk_update
    end
  end

  # Sensor data routes
  resources :sensor_data, only: [:index, :show, :create] do
    collection do
      get :latest
      get :by_device
      get :statistics
    end
  end

  # Root path serves dashboard
  root to: redirect('/dashboard')
end
