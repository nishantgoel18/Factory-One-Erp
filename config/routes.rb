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


  namespace :inventory do
    # Dashboard
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    
    # ===================================
    # PURCHASE ORDERS
    # ===================================
    resources :purchase_orders do
      member do
        get :confirm      # DRAFT → CONFIRMED
        get :cancel       # Cancel PO
        get :close        # RECEIVED → CLOSED
        get :print         # Print PO
      end
      
      collection do
        get :open_pos      # All open POs needing receiving
        get :overdue       # Overdue deliveries
      end
      
      # Nested lines for AJAX operations
      resources :lines, controller: 'purchase_order_lines', only: [:create, :update, :destroy]
    end
    
    # ===================================
    # GOODS RECEIPTS (GRN)
    # ===================================
    resources :goods_receipts do
      member do
        get :post_receipt  # DRAFT → POSTED (creates transactions)
        get :print
      end
      
      collection do
        get :from_po        # Create GRN from PO
      end
      
      resources :lines, controller: 'goods_receipt_lines', only: [:create, :update, :destroy]
    end
    
    # ===================================
    # STOCK ISSUES
    # ===================================

    resources :stock_batches do
      collection do
        get :search  # AJAX endpoint for batch search/autocomplete
      end
    end
    resources :stock_issues do
      member do
        get :post_issue   # DRAFT → POSTED
        get :print
      end
      
      resources :lines, controller: 'stock_issue_lines', only: [:create, :update, :destroy]
    end
    
    # ===================================
    # STOCK TRANSFERS
    # ===================================
    resources :stock_transfers do
      member do
        get :post_transfer  # DRAFT → POSTED
        get :print
      end
      
      resources :lines, controller: 'stock_transfer_lines', only: [:create, :update, :destroy]
    end
    
    # ===================================
    # STOCK ADJUSTMENTS
    # ===================================
    resources :stock_adjustments do
      member do
        get :post_adjustment  # DRAFT → POSTED
        get :print
      end
      
      resources :lines, controller: 'stock_adjustment_lines', only: [:create, :update, :destroy]
    end
    
    # ===================================
    # CYCLE COUNTS
    # ===================================
    resources :cycle_counts do
      member do
        get :start_counting    # SCHEDULED → IN_PROGRESS
        get :complete_count    # IN_PROGRESS → COMPLETED
        get :post_count        # COMPLETED → POSTED
        get :print
        get :variance_report
      end
      
      collection do
        get :upcoming
        get :overdue
      end
      
      resources :lines, controller: 'cycle_count_lines', only: [:create, :update, :destroy] do
        member do
          patch :record_count  # Update counted_qty
        end
      end
    end

    # ===================================
    # REPORTS & ANALYTICS
    # ===================================
    namespace :reports do
      get 'stock_levels'           # Current inventory
      get 'stock_movements'        # Transaction history
      get 'valuation'              # Inventory valuation
      get 'aging'                  # Inventory aging
      get 'receiving_performance'  # GRN metrics
      get 'variance_analysis'      # Cycle count variances
      get 'low_stock'              # Items below reorder point
    end
    
    # ===================================
    # AJAX ENDPOINTS
    # ===================================
    namespace :ajax do
      get 'products/search'               # Product autocomplete
      get 'locations/for_warehouse'       # Locations by warehouse
      get 'batches/for_product'           # Batches for product
      get 'stock_level/check'             # Check available stock
      get 'po_lines/for_receiving'        # PO lines available for GRN
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
