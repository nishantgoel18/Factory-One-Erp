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
      get :dashboard              # Analytics dashboard view
      get :statement              # Customer statement PDF
      post :credit_hold           # Place/remove credit hold
      get '/delete', to: 'customers#destroy', as: :delete  # Soft delete (keep your pattern)
    end
    
    collection do
      get :autocomplete           # For search autocomplete
      post :bulk_action           # Bulk operations (activate, deactivate, export, delete)
    end
    
    resources :addresses, controller: 'customers/addresses', only: [:new, :create, :edit, :update, :destroy] do
      member do
        post :make_default        # Set as default address
      end
    end
    
    resources :contacts, controller: 'customers/contacts', only: [:new, :create, :edit, :update, :destroy] do
      member do
        post :make_primary        # Set as primary contact
      end
    end
    
    resources :documents, controller: 'customers/documents', only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        get :download             # Download document file
      end
    end
    
    resources :activities, controller: 'customers/activities', only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        post :complete            # Mark activity as completed
        post :reschedule          # Reschedule activity
      end
    end
  end

  resources :suppliers do
    # Member routes (specific supplier)
    member do
      get 'dashboard'           # Analytics dashboard
      get 'approve'            # Approve supplier
      get 'suspend'            # Suspend supplier
      get 'blacklist'          # Blacklist supplier
      get 'reactivate'         # Reactivate supplier
    end
    
    # Collection routes (all suppliers)
    collection do
      get 'autocomplete'        # For search/selection dropdowns
      post 'bulk_action'        # Bulk operations
      get 'comparison'          # Compare multiple suppliers
    end
    
    # Nested resources
    scope module: :suppliers do
      resources :addresses, except: [:index, :show] do
        member do
          post 'make_default'   # Set as default address
        end
      end
      
      resources :contacts, except: [:index, :show] do
        member do
          post 'make_primary'   # Set as primary contact
        end
      end
      
      resources :products do
        member do
          post 'update_price'   # Update product price
        end
      end
      
      resources :quality_issues do
        member do
          post 'resolve'        # Mark issue as resolved
          post 'close'          # Close issue
        end
      end
      
      resources :activities, except: [:index] do
        member do
          post 'complete'       # Mark activity as completed
        end
      end
      
      resources :documents, only: [:index, :new, :create, :edit, :update, :destroy] do
        member do
          get 'download'        # Download document
        end
      end
      
      resources :performance_reviews, only: [:index, :show, :new, :create, :edit, :update] do
        member do
          post 'approve'        # Approve review
          post 'share'          # Share with supplier
        end
      end
    end
  end

  resources :rfqs do
    member do
      post 'remind_supplier'  
      post 'send_to_suppliers'      # Send RFQ to invited suppliers
      get 'comparison'              # Comparison dashboard ⭐
      post 'award'                  # Award to supplier
      post 'close'                  # Close RFQ
      post 'cancel'                 # Cancel RFQ
      post 'invite_suppliers'       # Invite suppliers to RFQ
      post 'select_quotes'          # Select winning quotes
    end
    
    collection do
      get 'autocomplete'            # Search autocomplete
    end
    
    # Nested RFQ Items (if needed for separate management)
    resources :rfq_items, only: [:new, :create, :edit, :update, :destroy]
      # Vendor quotes for each line item
    resources :vendor_quotes do
      member do
        post 'select'             # Select this quote as winner
        post 'reject'             # Reject quote
      end
    end
  end

  get '/rfqs/:rfq_id/conversions', to: 'rfq_conversions#new', as: :new_rfq_conversion
  post '/rfqs/:rfq_id/conversions', to: 'rfq_conversions#new', as: :create_rfq_conversion


  resources :work_centers do
    member do
      patch :toggle_status  # For activating/deactivating
    end
    
    collection do
      get :generate_code  # For auto-generating next code
    end
  end


  resources :routings do
    member do
      patch :toggle_status
      post :duplicate  # For creating copies
    end
    
    collection do
      get :generate_code
    end
    
    # Nested operations management (optional, for AJAX)
    resources :routing_operations, only: [:create, :update, :destroy], shallow: true
  end
  
  resources :work_orders do
    member do
      get :release              # Release WO to production
      get :start_production     # Start production
      get :complete             # Complete WO
      get :cancel               # Cancel WO
      post :send_shortage_alert  # ADD THIS
    end
    
    # Nested routes for operations
    resources :work_order_operations, only: [] do
      member do
        post :start              # Start operation
        post :complete           # Complete operation
        patch :update_time
           # NEW       # Update time tracking
      end
    end
    
    # Nested routes for materials
    resources :work_order_materials, only: [] do
      member do
        post :allocate           # Allocate material
        post :issue              # Issue to production
        post :record_consumption # Record actual consumption
        post :return_material    # Return excess
      end
    end

    member do
      get 'assign_operators', to: 'operator_assignments#edit'
      patch 'assign_operators', to: 'operator_assignments#update'
    end
  end

  post 'operations/:operation_id/assign', to: 'operator_assignments#assign_single', as: :assign_operation

  resources :labor_time_entries, only: [] do
    collection do
      get :my_timesheet
      get :shop_floor
      post :clock_in    # NEW
      post :clock_out 
    end
  end
  
  # Shortcut routes
  get 'shop_floor', to: 'labor_time_entries#shop_floor'
  get 'my_timesheet', to: 'labor_time_entries#my_timesheet'

  scope :tools do
    get 'production_calculator', to: 'production_calculator#index'
    post 'production_calculator/calculate', to: 'production_calculator#calculate'
  end

  scope :reports do
    scope :inventory do
      get 'stock_levels', to: 'inventory_reports#stock_levels'           # Current inventory
      get 'stock_movements', to: 'inventory_reports#stock_movements'        # Transaction history
      get 'valuation', to: 'inventory_reports#valuation'                # Inventory valuation
      get 'aging', to: 'inventory_reports#aging'                   # Inventory aging
      get 'receiving_performance', to: 'inventory_reports#receiving_performance'   # GRN metrics
      get 'variance_analysis', to: 'inventory_reports#variance_analysis'     # Cycle count variances
      get 'low_stock', to: 'inventory_reports#low_stock'              # Items below reorder point
    end

    resource :routing, only: [] do
      collection do
        get :index, to: 'routing_reports#index'
        get :work_center_utilization, to: 'routing_reports#work_center_utilization'
        get :routing_cost_analysis, to: 'routing_reports#routing_cost_analysis'
        get :production_time_analysis, to: 'routing_reports#production_time_analysis'
        get :routing_comparison, to: 'routing_reports#routing_comparison'
        get :operations_summary, to: 'routing_reports#operations_summary'
      end
    end

    resource :work_order, only: [] do
      collection do
        get :index, to: 'work_order_reports#index'
        get :status_report, to: 'work_order_reports#status_report'
        get :cost_variance_report, to: 'work_order_reports#cost_variance_report'
        get :efficiency_report, to: 'work_order_reports#efficiency_report'
        get :material_consumption_report, to: 'work_order_reports#material_consumption_report'
      end
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
  get '/production/home', to: 'dashboards#production_dashboard', as: :production_home
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
