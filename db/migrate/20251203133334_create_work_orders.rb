# db/migrate/20251203XXXXXX_create_work_orders.rb

class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      # Identification
      t.string     :wo_number, limit: 50, null: false
      
      # Product & Configuration References
      t.references :product, null: false, foreign_key: true
      t.references :bom, foreign_key: { to_table: :bill_of_materials }
      t.references :routing, foreign_key: true
      t.references :customer, foreign_key: true # Optional - if making for specific customer
      t.references :warehouse, null: false, foreign_key: true
      
      # Quantities
      t.decimal    :quantity_to_produce, precision: 14, scale: 4, null: false
      t.decimal    :quantity_completed, precision: 14, scale: 4, default: 0.0
      t.decimal    :quantity_scrapped, precision: 14, scale: 4, default: 0.0
      t.references :uom, null: false, foreign_key: { to_table: :unit_of_measures }
      
      # Status & Priority
      t.string     :status, limit: 20, default: 'NOT_STARTED', null: false
      t.string     :priority, limit: 10, default: 'NORMAL'
      
      # Scheduling
      t.date       :scheduled_start_date
      t.date       :scheduled_end_date
      t.datetime   :actual_start_date
      t.datetime   :actual_end_date
      
      # Planned Costs (calculated from BOM + Routing)
      t.decimal    :planned_material_cost, precision: 12, scale: 2, default: 0.0
      t.decimal    :planned_labor_cost, precision: 12, scale: 2, default: 0.0
      t.decimal    :planned_overhead_cost, precision: 12, scale: 2, default: 0.0
      
      # Actual Costs (tracked during execution)
      t.decimal    :actual_material_cost, precision: 12, scale: 2, default: 0.0
      t.decimal    :actual_labor_cost, precision: 12, scale: 2, default: 0.0
      t.decimal    :actual_overhead_cost, precision: 12, scale: 2, default: 0.0
      
      # Notes
      t.text       :notes
      
      # Audit Trail - Who did what when
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :released_by, foreign_key: { to_table: :users }
      t.references :completed_by, foreign_key: { to_table: :users }
      
      t.datetime   :released_at
      t.datetime   :completed_at
      
      # Soft Delete
      t.boolean    :deleted, default: false
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :work_orders, :wo_number, unique: true
    add_index :work_orders, :status
    add_index :work_orders, :priority
    add_index :work_orders, [:product_id, :status]
    add_index :work_orders, [:warehouse_id, :status]
    add_index :work_orders, :scheduled_start_date
    add_index :work_orders, :scheduled_end_date
    add_index :work_orders, :deleted
  end
end