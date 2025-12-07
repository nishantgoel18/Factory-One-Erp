# db/migrate/20251203XXXXXX_create_work_order_materials.rb

class CreateWorkOrderMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_materials do |t|
      # Parent References
      t.references :work_order, null: false, foreign_key: true
      t.references :bom_item, foreign_key: true  # Which BOM line this came from
      
      # Material Details
      t.references :product, null: false, foreign_key: true  # The component/material
      
      # Quantities
      t.decimal    :quantity_required, precision: 14, scale: 4, null: false
      t.decimal    :quantity_allocated, precision: 14, scale: 4, default: 0.0
      t.decimal    :quantity_consumed, precision: 14, scale: 4, default: 0.0
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # Inventory Details
      t.references :batch, foreign_key: { to_table: :stock_batches }  # If batch tracked
      t.references :location, foreign_key: true  # Where to pick from
      
      # Costing
      t.decimal    :unit_cost, precision: 12, scale: 4, default: 0.0
      t.decimal    :total_cost, precision: 12, scale: 2, default: 0.0
      
      # Issue Tracking
      t.datetime   :allocated_at
      t.datetime   :issued_at
      t.references :issued_by, foreign_key: { to_table: :users }
      
      # Status
      t.string     :status, limit: 20, default: 'REQUIRED'
      # REQUIRED → ALLOCATED → ISSUED → CONSUMED
      
      # Notes
      t.text       :notes
      
      # Soft Delete
      t.boolean    :deleted, default: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :work_order_materials, [:work_order_id, :product_id]
    add_index :work_order_materials, :status
    add_index :work_order_materials, [:location_id, :product_id]
    add_index :work_order_materials, :deleted
  end
end
