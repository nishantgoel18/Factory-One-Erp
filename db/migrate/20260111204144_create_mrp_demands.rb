class CreateMrpDemands < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_demands do |t|
      # Associations
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      
      # Demand source (polymorphic)
      t.string :source_type, limit: 50, null: false
      # 'SALES_ORDER', 'FORECAST', 'SAFETY_STOCK', 'WORK_ORDER', 'REORDER_POINT'
      t.bigint :source_id
      t.string :source_reference, limit: 100
      
      # Demand details
      t.date :required_date, null: false
      t.decimal :quantity, precision: 14, scale: 4, null: false
      t.decimal :consumed_quantity, precision: 14, scale: 4, default: 0.0
      t.decimal :remaining_quantity, precision: 14, scale: 4
      
      # Priority
      t.string :priority, limit: 20, default: 'NORMAL'
      t.integer :priority_score, default: 50
      
      # Additional info
      t.references :customer, foreign_key: true
      t.string :customer_po_number, limit: 100
      
      # Status
      t.boolean :is_firm, default: false  # Firm (SO) vs forecast
      t.boolean :is_active, default: true
      
      # Metadata
      t.jsonb :metadata, default: {}
      
      t.boolean :deleted, default: false
      t.timestamps
    end
    add_index :mrp_demands, [:organization_id, :product_id, :required_date]
    add_index :mrp_demands, [:mrp_run_id, :product_id]
    add_index :mrp_demands, [:source_type, :source_id]
    add_index :mrp_demands, :required_date
    add_index :mrp_demands, :is_firm
    add_index :mrp_demands, :deleted
  end
end
