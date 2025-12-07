class CreateLaborTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :labor_time_entries do |t|
      # References
      t.references :work_order_operation, null: false, foreign_key: true
      t.references :operator, null: false, foreign_key: { to_table: :users }
      
      # Time tracking
      t.datetime :clock_in_at, null: false
      t.datetime :clock_out_at
      t.decimal :hours_worked, precision: 10, scale: 4, default: 0.0
      
      # Entry details
      t.string :entry_type, default: 'REGULAR'  # REGULAR, BREAK, OVERTIME
      t.text :notes
      
      # Audit
      t.boolean :deleted, default: false
      t.timestamps
    end
    
    # Indexes
    add_index :labor_time_entries, [:work_order_operation_id, :operator_id], 
              name: 'index_labor_entries_on_operation_and_operator'
    add_index :labor_time_entries, :clock_in_at
    add_index :labor_time_entries, :clock_out_at
    add_index :labor_time_entries, [:operator_id, :clock_in_at]
    add_index :labor_time_entries, :deleted
  end
end
