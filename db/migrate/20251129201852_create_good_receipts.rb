class CreateGoodReceipts < ActiveRecord::Migration[8.1]
  def change
    # ===================================
    # GOODS RECEIPT (GRN) HEADER
    # ===================================
    create_table :goods_receipts do |t|
      # Reference & Status
      t.string :reference_no, null: false, limit: 50
      t.string :status, default: 'DRAFT', null: false, limit: 20
      
      # Warehouse reference
      t.references :warehouse, null: false, foreign_key: true
      
      # Link to Purchase Order
      t.references :purchase_order, foreign_key: true, null: true
      
      # Supplier reference (optional - if receiving from supplier)
      t.references :supplier, foreign_key: true, null: true
      
      # Dates
      t.date :receipt_date, null: false, default: -> { 'CURRENT_DATE' }
      t.datetime :posted_at
      
      # User tracking
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :posted_by, foreign_key: { to_table: :users }, null: true
      
      # Notes
      t.text :notes
      
      # Soft delete
      t.boolean :deleted, default: false, null: false
      
      t.timestamps
    end
    
    # Index for quick lookups
    add_index :goods_receipts, :reference_no, unique: true
    add_index :goods_receipts, :status
    add_index :goods_receipts, [:warehouse_id, :status]
  end
end
