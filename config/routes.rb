Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#index'

  # Dashboard JSON API endpoints
  get '/api/dashboard', to: 'dashboard#index'
  get '/api/dashboard/realtime', to: 'dashboard#realtime'
  get '/api/dashboard/statistics', to: 'dashboard#statistics'

  # API routes
  namespace :api do
    namespace :v1 do
      # Device management
      resources :devices do
        member do
          get :sensor_data
          post :sensor_data, action: :create_sensor_data
          get :analytics
        end
      end

      # Device status summary
      get 'devices_status', to: 'devices#status_summary'
    end
  end

  # Root path serves static dashboard HTML
  root to: redirect('/dashboard.html')
end
