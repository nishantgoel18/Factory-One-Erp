  # frozen_string_literal: true

# ============================================================================
# MIGRATION: Create Customer Contacts Table
# ============================================================================
# Manages multiple contact persons per customer with roles and preferences
#
# Run: rails generate migration CreateCustomerContacts
# ============================================================================

class CreateCustomerContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_contacts do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :customer, null: false, foreign_key: true, index: true
      
      # ========================================
      # CONTACT IDENTIFICATION
      # ========================================
      t.string :first_name, limit: 100, null: false
      t.string :last_name, limit: 100, null: false
      t.string :title, limit: 100  # Job title: VP Operations, Purchasing Manager, etc.
      t.string :department, limit: 100  # Purchasing, Finance, Operations, etc.
      
      # ========================================
      # CONTACT ROLE & STATUS
      # ========================================
      t.string :contact_role, limit: 30, null: false  # PRIMARY, PURCHASING, FINANCE, TECHNICAL, SHIPPING, DECISION_MAKER, OTHER
      t.boolean :is_primary_contact, default: false
      t.boolean :is_decision_maker, default: false
      t.boolean :is_active, default: true
      
      # ========================================
      # CONTACT INFORMATION
      # ========================================
      t.string :email, limit: 255
      t.string :phone, limit: 20
      t.string :mobile, limit: 20
      t.string :fax, limit: 20
      t.string :extension, limit: 10
      
      # ========================================
      # SOCIAL & PROFESSIONAL
      # ========================================
      t.string :linkedin_url
      t.string :skype_id, limit: 100
      
      # ========================================
      # COMMUNICATION PREFERENCES
      # ========================================
      t.string :preferred_contact_method, limit: 20, default: "EMAIL"  # EMAIL, PHONE, BOTH, SMS
      t.text :contact_notes  # Special instructions, preferences, etc.
      t.boolean :receive_order_confirmations, default: true
      t.boolean :receive_shipping_notifications, default: true
      t.boolean :receive_invoice_copies, default: false
      t.boolean :receive_marketing_emails, default: false
      
      # ========================================
      # PERSONAL INFO (Optional - CRM features)
      # ========================================
      t.date :birthday
      t.date :anniversary
      t.text :personal_notes  # Hobbies, interests (for relationship building)
      
      # ========================================
      # INTERACTION TRACKING
      # ========================================
      t.datetime :last_contacted_at
      t.string :last_contacted_by, limit: 100  # User name or method
      t.text :last_interaction_notes
      
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
    add_index :customer_contacts, [:customer_id, :contact_role]
    add_index :customer_contacts, [:customer_id, :is_primary_contact]
    add_index :customer_contacts, [:customer_id, :deleted]
    add_index :customer_contacts, :email
    add_index :customer_contacts, :is_active
    add_index :customer_contacts, [:last_name, :first_name]
  end
end
