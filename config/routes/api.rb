namespace :api do
  namespace :v1 do
    resources :datasets, only: [] do
      member do
        get :export
      end
    end
  end
end
