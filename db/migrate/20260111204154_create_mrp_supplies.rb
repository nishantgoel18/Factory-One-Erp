class CreateMrpSupplies < ActiveRecord::Migration[8.1]
  def change
    create_table :mrp_supplies do |t|
      # Associations
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :mrp_run, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      
      # Supply source (polymorphic)
      t.string :source_type, limit: 50, null: false
      # 'ON_HAND', 'PURCHASE_ORDER', 'WORK_ORDER', 'PLANNED_PO', 
      # 'PLANNED_WO', 'IN_TRANSIT', 'SAFETY_STOCK'
      t.bigint :source_id
      t.string :source_reference, limit: 100
      
      # Supply details
      t.date :available_date, null: false
      t.decimal :quantity, precision: 14, scale: 4, null: false
      t.decimal :allocated_quantity, precision: 14, scale: 4, default: 0.0
      t.decimal :remaining_quantity, precision: 14, scale: 4
      
      # Quality status
      t.string :quality_status, limit: 30, default: 'APPROVED'
      # 'APPROVED', 'HOLD', 'QUARANTINE', 'REJECTED'
      
      # Additional info
      t.references :supplier, foreign_key: true
      t.references :warehouse, foreign_key: true
      t.references :location, foreign_key: true
      
      # Status
      t.boolean :is_available, default: true
      t.boolean :is_allocated, default: false
      
      # Metadata
      t.jsonb :metadata, default: {}
      
      t.boolean :deleted, default: false
      t.timestamps
    end
    add_index :mrp_supplies, [:organization_id, :product_id, :available_date]
    add_index :mrp_supplies, [:mrp_run_id, :product_id]
    add_index :mrp_supplies, [:source_type, :source_id]
    add_index :mrp_supplies, :available_date
    add_index :mrp_supplies, :is_available
    add_index :mrp_supplies, :deleted
  end
end
