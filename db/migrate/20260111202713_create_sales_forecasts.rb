class CreateSalesForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_forecasts do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :customer, foreign_key: true, index: true  # Optional - specific customer forecast
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      
      # ========================================
      # FORECAST IDENTIFICATION
      # ========================================
      t.string :forecast_number, limit: 50, null: false
      t.string :forecast_name, limit: 200
      
      # ========================================
      # TIME PERIOD
      # ========================================
      t.string :period_type, limit: 20, default: 'MONTHLY', null: false
      # Options: 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'
      
      t.date :period_start_date, null: false
      t.date :period_end_date, null: false
      
      t.integer :year, null: false
      t.integer :month  # For monthly forecasts (1-12)
      t.integer :week   # For weekly forecasts (1-53)
      t.integer :quarter  # For quarterly forecasts (1-4)
      
      # ========================================
      # FORECAST QUANTITY
      # ========================================
      t.decimal :forecasted_quantity, precision: 14, scale: 4, null: false
      t.decimal :actual_quantity, precision: 14, scale: 4, default: 0.0  # Actuals for comparison
      t.decimal :consumed_quantity, precision: 14, scale: 4, default: 0.0  # How much used by MRP
      t.decimal :remaining_quantity, precision: 14, scale: 4  # Available for planning
      
      # ========================================
      # FORECAST METADATA
      # ========================================
      t.string :forecast_type, limit: 30, default: 'MANUAL'
      # Options: 'MANUAL', 'STATISTICAL', 'HISTORICAL', 'COLLABORATIVE', 'AI_GENERATED'
      
      t.string :forecast_method, limit: 50
      # Examples: 'MOVING_AVERAGE', 'EXPONENTIAL_SMOOTHING', 'LINEAR_REGRESSION', 
      #           'SEASONAL_DECOMPOSITION', 'HOLT_WINTERS'
      
      t.decimal :confidence_level, precision: 5, scale: 2, default: 100.0
      # 0-100% - How confident are we in this forecast
      
      t.string :confidence_category, limit: 20
      # Options: 'HIGH', 'MEDIUM', 'LOW'
      
      # ========================================
      # STATISTICAL DATA
      # ========================================
      t.decimal :standard_deviation, precision: 14, scale: 4
      t.decimal :mean_absolute_deviation, precision: 14, scale: 4
      t.decimal :forecast_error, precision: 14, scale: 4
      t.decimal :forecast_bias, precision: 14, scale: 4
      
      # ========================================
      # BUSINESS CONTEXT
      # ========================================
      t.string :demand_driver, limit: 100
      # What's driving this forecast? (e.g., "Holiday Season", "New Product Launch")
      
      t.string :market_segment, limit: 100
      t.string :sales_channel, limit: 100
      
      # ========================================
      # MRP CONSUMPTION
      # ========================================
      t.boolean :include_in_mrp, default: true
      t.string :consumption_method, limit: 30, default: 'FORWARD'
      # Options: 'FORWARD' (use forecast if no orders), 
      #          'BACKWARD' (reduce forecast by orders), 
      #          'FORWARD_BACKWARD' (both)
      
      t.integer :consumption_days_forward, default: 30
      t.integer :consumption_days_backward, default: 7
      
      # ========================================
      # VERSION CONTROL
      # ========================================
      t.string :version, limit: 20, default: 'V1'
      t.integer :revision_number, default: 1
      t.references :superseded_by, foreign_key: { to_table: :sales_forecasts }
      
      # ========================================
      # STATUS & WORKFLOW
      # ========================================
      t.string :status, limit: 30, default: 'DRAFT'
      # Options: 'DRAFT', 'SUBMITTED', 'APPROVED', 'ACTIVE', 'EXPIRED', 'ARCHIVED', 'REJECTED'
      
      t.datetime :submitted_at
      t.datetime :approved_at
      t.datetime :expired_at
      
      # ========================================
      # ADDITIONAL INFO
      # ========================================
      t.text :notes
      t.text :assumptions  # Business assumptions behind forecast
      t.jsonb :metadata, default: {}  # Store additional data
      
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :sales_forecasts, :forecast_number, unique: true
    add_index :sales_forecasts, [:organization_id, :product_id, :period_start_date]
    add_index :sales_forecasts, [:year, :month], where: "month IS NOT NULL"
    add_index :sales_forecasts, [:year, :quarter], where: "quarter IS NOT NULL"
    add_index :sales_forecasts, :status
    add_index :sales_forecasts, :include_in_mrp
    add_index :sales_forecasts, :deleted
    add_index :sales_forecasts, [:period_start_date, :period_end_date]
  end
end
