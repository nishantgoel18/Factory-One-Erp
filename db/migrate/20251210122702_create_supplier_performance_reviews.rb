class CreateSupplierPerformanceReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_performance_reviews do |t|
      # Foreign Key
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # Review Period
      t.string :review_period # e.g., "Q1 2025", "2024 Annual"
      t.date :period_start_date, null: false
      t.date :period_end_date, null: false
      t.date :review_date, null: false
      
      # Review Type
      t.string :review_type, default: 'QUARTERLY' 
      t.string :review_status, default: 'DRAFT' # DRAFT, COMPLETED, APPROVED, SHARED_WITH_SUPPLIER
      
      # Performance Scores (0-100 scale)
      t.decimal :overall_score, precision: 5, scale: 2
      t.decimal :quality_score, precision: 5, scale: 2
      t.decimal :delivery_score, precision: 5, scale: 2
      t.decimal :cost_score, precision: 5, scale: 2
      t.decimal :service_score, precision: 5, scale: 2
      t.decimal :responsiveness_score, precision: 5, scale: 2
      t.decimal :innovation_score, precision: 5, scale: 2
      
      # Performance Rating
      t.string :performance_rating # EXCELLENT, GOOD, SATISFACTORY, NEEDS_IMPROVEMENT, UNACCEPTABLE
      
      # Detailed Metrics for Period
      # Quality Metrics
      t.integer :total_receipts_count
      t.integer :receipts_rejected_count
      t.decimal :quality_acceptance_rate, precision: 5, scale: 2
      t.integer :quality_issues_count
      t.integer :critical_issues_count
      
      # Delivery Metrics
      t.integer :total_deliveries_count
      t.integer :on_time_deliveries_count
      t.integer :late_deliveries_count
      t.decimal :on_time_delivery_rate, precision: 5, scale: 2
      t.decimal :average_delay_days, precision: 8, scale: 2
      
      # Cost Metrics
      t.decimal :total_spend_amount, precision: 15, scale: 2
      t.decimal :price_variance_percentage, precision: 5, scale: 2 # vs target/budget
      t.integer :price_increases_count
      t.integer :price_decreases_count
      
      # Order Metrics
      t.integer :total_orders_count
      t.decimal :average_order_value, precision: 15, scale: 2
      t.decimal :order_fill_rate, precision: 5, scale: 2 # % of quantity delivered vs ordered
      
      # Strengths & Areas for Improvement
      t.text :strengths # Positive aspects
      t.text :areas_for_improvement
      t.text :action_items
      t.text :supplier_feedback # Feedback from supplier if shared
      
      # Strategic Assessment
      t.text :strategic_importance # How critical is this supplier?
      t.text :risk_assessment
      t.text :relationship_status # How is the business relationship?
      t.boolean :recommend_continuation, default: true
      t.boolean :recommend_expansion, default: false
      t.boolean :recommend_reduction, default: false
      t.boolean :recommend_termination, default: false
      t.text :recommendation_notes
      
      # Future Outlook
      t.text :future_opportunities
      t.text :future_concerns
      t.date :next_review_date
      
      # Reviewers
      t.references :reviewed_by, foreign_key: { to_table: :users } # Primary reviewer
      t.references :approved_by, foreign_key: { to_table: :users }
      t.date :approved_date
      
      # Sharing with Supplier
      t.boolean :shared_with_supplier, default: false
      t.date :shared_date
      t.references :shared_by, foreign_key: { to_table: :users }
      
      # Notes
      t.text :internal_notes # Not shared with supplier
      t.text :supplier_comments # Supplier's response to review
      
      # Audit
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :supplier_performance_reviews, :review_date
    add_index :supplier_performance_reviews, :review_status
    add_index :supplier_performance_reviews, [:supplier_id, :review_date]
    add_index :supplier_performance_reviews, [:period_start_date, :period_end_date]
    add_index :supplier_performance_reviews, :overall_score
  end
end
