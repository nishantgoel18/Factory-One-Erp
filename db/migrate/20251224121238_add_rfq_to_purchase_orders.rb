class AddRfqToPurchaseOrders < ActiveRecord::Migration[8.1]
  def change
    # Link PO to originating RFQ
    add_reference :purchase_orders, :rfq, foreign_key: true, index: true
    
    # Link PO Lines to RFQ Items for traceability
    add_reference :purchase_order_lines, :rfq_item, foreign_key: true, index: true
    
    # Link PO Lines to specific Vendor Quote selected
    add_reference :purchase_order_lines, :vendor_quote, foreign_key: true, index: true
    
    # Add conversion tracking to RFQ
    add_column :rfqs, :po_numbers, :string, comment: "Comma-separated list of generated PO numbers"
    add_column :rfqs, :conversion_date, :date, comment: "Date when RFQ was converted to PO(s)"
    add_column :rfqs, :converted_by_id, :bigint, comment: "User who converted RFQ to PO"
    
    add_index :rfqs, :conversion_date
    add_index :rfqs, :converted_by_id
  end
end