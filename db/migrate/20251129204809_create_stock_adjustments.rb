class CreateStockAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_adjustments do |t|
      # Reference & Status
      t.string :reference_no, null: false, limit: 50
      t.string :status, default: 'DRAFT', null: false, limit: 20
      
      # Warehouse reference
      t.references :warehouse, null: false, foreign_key: true
      
      # Adjustment reason (text field for explanation)
      t.text :reason, null: false
      
      # Dates
      t.date :adjustment_date, null: false, default: -> { 'CURRENT_DATE' }
      t.datetime :posted_at
      
      # User tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :posted_by, foreign_key: { to_table: :users }, null: true
      t.references :approved_by, foreign_key: { to_table: :users }, null: true
      
      # Notes
      t.text :notes
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :stock_adjustments, :reference_no, unique: true
    add_index :stock_adjustments, :status
    add_index :stock_adjustments, [:warehouse_id, :status]
    add_index :stock_adjustments, :adjustment_date
  end
end
