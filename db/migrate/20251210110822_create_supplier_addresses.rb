# frozen_string_literal: true

class CreateSupplierAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_addresses do |t|
      # ============================================================================
      # FOREIGN KEY
      # ============================================================================
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # ============================================================================
      # ADDRESS TYPE
      # ============================================================================
      t.string :address_type, null: false # PRIMARY_OFFICE, FACTORY, WAREHOUSE, BILLING, RETURNS, OTHER
      t.string :address_label # e.g., "Main Factory", "Warehouse 2"
      t.boolean :is_default, default: false
      t.boolean :is_active, default: true
      
      # ============================================================================
      # ADDRESS DETAILS
      # ============================================================================
      t.string :attention_to
      t.string :street_address_1, null: false
      t.string :street_address_2
      t.string :city, null: false
      t.string :state_province
      t.string :postal_code, null: false
      t.string :country, null: false, default: 'US'
      
      # ============================================================================
      # CONTACT AT THIS LOCATION
      # ============================================================================
      t.string :contact_phone
      t.string :contact_email
      t.string :contact_fax
      
      # ============================================================================
      # OPERATIONAL DETAILS
      # ============================================================================
      t.string :operating_hours # e.g., "8am-5pm Mon-Fri"
      t.string :receiving_hours # For deliveries
      t.text :shipping_instructions
      t.text :special_instructions
      t.string :dock_gate_info
      t.boolean :requires_appointment, default: false
      t.string :access_code
      
      # ============================================================================
      # FACILITY DETAILS (for factories/warehouses)
      # ============================================================================
      t.integer :facility_size_sqft
      t.integer :warehouse_capacity_pallets
      t.text :equipment_available # Array of equipment
      t.text :certifications_at_location # Array of certifications
      
      # ============================================================================
      # GEOCODING
      # ============================================================================
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      
      # ============================================================================
      # AUDIT FIELDS
      # ============================================================================
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    # ============================================================================
    # INDEXES
    # ============================================================================
    add_index :supplier_addresses, [:supplier_id, :address_type]
    add_index :supplier_addresses, [:supplier_id, :is_default]
    add_index :supplier_addresses, :is_active
    add_index :supplier_addresses, :country
  end
end