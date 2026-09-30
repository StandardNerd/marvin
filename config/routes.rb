Rails.application.routes.draw do
  # Authentication
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  get 'signup', to: 'registrations#new'
  post 'signup', to: 'registrations#create'

  # Projects (main resource)
  resources :projects do
    resources :datasets, except: [:index] do
      member do
        post :process_file
      end
      resources :dataset_examples, only: [:show, :edit, :update, :destroy] do
        member do
          post :accept
          post :reject
        end
        collection do
          post :bulk_action
        end
      end
    end
    resources :training_runs, except: [:index] do
      member do
        post :start
        post :cancel
        get :metrics
      end
      resources :evaluations, only: [:new, :create, :show]
    end
    resources :model_artifacts, only: [:new, :create, :show, :index] do
      member do
        get :download
      end
    end
  end

  # Global views
  resources :experiments, only: [:index] do
    collection do
      get :compare
    end
  end

  # API endpoints for ML worker callbacks
  namespace :api do
    namespace :v1 do
      resources :training_callbacks, only: [:update] do
        member do
          post :metrics
          post :complete
          post :fail
        end
      end
      resources :evaluation_callbacks, only: [] do
        member do
          post :complete
          post :fail
        end
      end
      resources :datasets, only: [] do
        member do
          get :export
        end
      end
    end
  end

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Root
  root 'projects#index'
end
