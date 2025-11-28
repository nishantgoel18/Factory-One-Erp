Rails.application.routes.draw do

  
  devise_for :users

  resources :accounts do
    member do
      get '/delete', to: 'accounts#destroy', as: :delete
    end
  end
  
  resources :journal_entries do
    member do
      get '/delete', to: 'journal_entries#destroy', as: :delete
      get '/post', to: 'journal_entries#post', as: :post
      get '/reverse', to: 'journal_entries#reverse', as: :reverse

    end
  end

  resources :locations do
    member do
      get '/delete', to: 'locations#destroy', as: :delete
    end
  end
  resources :warehouses do
    member do
      get '/delete', to: 'warehouses#destroy', as: :delete
    end
  end
  resources :products do
    member do
      get '/delete', to: 'products#destroy', as: :delete
    end
    resources :bill_of_materials do
      member do
        get '/activate', to: 'bill_of_materials#activate', as: :activate
        get '/delete', to: 'bill_of_materials#destroy', as: :delete
      end
    end #, shallow: true
  end

  resources :product_categories do
    member do
      get '/delete', to: 'product_categories#destroy', as: :delete
    end
  end

  resources :unit_of_measures do
    member do
      get '/delete', to: 'unit_of_measures#destroy', as: :delete
    end
  end

  resources :tax_codes do
    member do
      get '/delete', to: 'tax_codes#destroy', as: :delete
    end
  end
  
  resources :customers do
    member do
      get '/delete', to: 'customers#destroy', as: :delete
    end
  end

  resources :suppliers do
    member do
      get '/delete', to: 'suppliers#destroy', as: :delete
    end
  end

  get '/home', to: 'dashboards#home', as: :home
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboards#home"
end
