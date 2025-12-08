class CreateCustomerAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_addresses do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :customer, null: false, foreign_key: true, index: true
      
      # ========================================
      # ADDRESS TYPE & STATUS
      # ========================================
      t.string :address_type, limit: 20, null: false  # BILLING, SHIPPING, BOTH, WAREHOUSE, OTHER
      t.string :address_label, limit: 100  # e.g., "Main Office", "West Coast Warehouse"
      t.boolean :is_default, default: false
      t.boolean :is_active, default: true
      
      # ========================================
      # CONTACT AT THIS ADDRESS
      # ========================================
      t.string :attention_to, limit: 100  # Person to contact at this address
      t.string :contact_phone, limit: 20
      t.string :contact_email
      
      # ========================================
      # ADDRESS DETAILS
      # ========================================
      t.string :street_address_1, limit: 255, null: false
      t.string :street_address_2, limit: 255
      t.string :city, limit: 100, null: false
      t.string :state_province, limit: 100
      t.string :postal_code, limit: 20, null: false
      t.string :country, limit: 2, default: "US", null: false  # ISO 2-letter country code
      
      # ========================================
      # ADDITIONAL DETAILS
      # ========================================
      t.text :delivery_instructions
      t.string :dock_gate_info, limit: 100  # Gate #, Dock #, etc.
      t.string :delivery_hours  # e.g., "Mon-Fri 8AM-5PM"
      t.boolean :residential_address, default: false
      t.boolean :requires_appointment, default: false
      t.string :access_code, limit: 50
      
      # ========================================
      # GEOCODING (Optional - for future mapping features)
      # ========================================
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      
      # ========================================
      # AUDIT FIELDS
      # ========================================
      t.boolean :deleted, default: false, null: false
      t.references :created_by, foreign_key: { to_table: :users }, index: true
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :customer_addresses, [:customer_id, :address_type]
    add_index :customer_addresses, [:customer_id, :is_default]
    add_index :customer_addresses, [:customer_id, :deleted]
    add_index :customer_addresses, :country
    add_index :customer_addresses, :postal_code
    add_index :customer_addresses, :is_active
  end
end
