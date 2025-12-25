class CreateRfqSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :rfq_suppliers do |t|
      # Foreign Keys
      t.references :rfq, null: false, foreign_key: true, index: true
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # Invitation Details
      t.datetime :invited_at, null: false
      t.string :invitation_status, default: 'INVITED' # INVITED, VIEWED, QUOTED, DECLINED, NO_RESPONSE
      t.datetime :viewed_at # When supplier viewed the RFQ
      t.datetime :quoted_at # When supplier submitted quote
      t.datetime :declined_at
      t.text :decline_reason
      
      # Response Tracking
      t.integer :response_time_hours # Time to respond in hours
      t.boolean :responded_on_time, default: true
      t.integer :days_overdue
      
      # Quote Summary (Rolled up from line items)
      t.decimal :total_quoted_amount, precision: 15, scale: 2
      t.integer :items_quoted_count, default: 0
      t.integer :items_not_quoted_count, default: 0
      t.boolean :quoted_all_items, default: false
      
      # Selection
      t.boolean :is_selected, default: false
      t.date :selected_date
      t.text :selection_notes
      
      # Email tracking
      t.datetime :last_email_sent_at
      t.integer :email_count, default: 0
      t.boolean :email_bounced, default: false
      
      # Contact used
      t.references :supplier_contact, foreign_key: true
      t.string :contact_email_used
      
      # Notes
      t.text :internal_notes
      
      # Audit
      t.references :invited_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :rfq_suppliers, [:rfq_id, :supplier_id], unique: true
    add_index :rfq_suppliers, :invitation_status
    add_index :rfq_suppliers, :is_selected
    add_index :rfq_suppliers, :invited_at
  end
end
