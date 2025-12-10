# frozen_string_literal: true

class CreateSupplierContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_contacts do |t|
      # ============================================================================
      # FOREIGN KEY
      # ============================================================================
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # ============================================================================
      # BASIC INFORMATION
      # ============================================================================
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :title # Job title
      t.string :department
      
      # ============================================================================
      # CONTACT ROLE
      # ============================================================================
      t.string :contact_role, null: false # SALES, TECHNICAL, ACCOUNTS_PAYABLE, QUALITY, SHIPPING, MANAGEMENT, PRIMARY, OTHER
      t.boolean :is_primary_contact, default: false
      t.boolean :is_decision_maker, default: false
      t.boolean :is_escalation_contact, default: false
      t.boolean :is_after_hours_contact, default: false
      t.boolean :is_active, default: true
      
      # ============================================================================
      # CONTACT DETAILS
      # ============================================================================
      t.string :email, null: false
      t.string :phone, null: false
      t.string :mobile
      t.string :fax
      t.string :extension
      t.string :direct_line
      
      # ============================================================================
      # DIGITAL CONTACT
      # ============================================================================
      t.string :skype_id
      t.string :linkedin_url
      t.string :wechat_id
      t.string :whatsapp_number
      t.string :preferred_contact_method # EMAIL, PHONE, MOBILE, WHATSAPP, WECHAT
      
      # ============================================================================
      # COMMUNICATION PREFERENCES
      # ============================================================================
      t.boolean :receive_pos, default: true
      t.boolean :receive_rfqs, default: true
      t.boolean :receive_quality_alerts, default: false
      t.boolean :receive_payment_confirmations, default: false
      t.boolean :receive_general_updates, default: false
      t.text :communication_notes
      
      # ============================================================================
      # AVAILABILITY
      # ============================================================================
      t.string :working_hours # e.g., "9am-6pm EST"
      t.string :timezone # e.g., "EST", "PST", "GMT+8"
      t.text :out_of_office_notes
      t.date :out_of_office_from
      t.date :out_of_office_to
      
      # ============================================================================
      # LANGUAGES
      # ============================================================================
      t.text :languages_spoken # Array: English, Spanish, Chinese, etc.
      
      # ============================================================================
      # RELATIONSHIP INFO
      # ============================================================================
      t.date :birthday
      t.date :anniversary
      t.text :personal_notes # CRM info
      t.text :professional_notes
      t.integer :relationship_strength, default: 1 # 1-5 scale
      
      # ============================================================================
      # ACTIVITY TRACKING
      # ============================================================================
      t.datetime :last_contacted_at
      t.references :last_contacted_by, foreign_key: { to_table: :users }
      t.integer :contact_frequency_days # Average days between contacts
      t.integer :total_interactions_count, default: 0
      
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
    add_index :supplier_contacts, [:supplier_id, :contact_role]
    add_index :supplier_contacts, [:supplier_id, :is_primary_contact]
    add_index :supplier_contacts, :email
    add_index :supplier_contacts, :is_active
    add_index :supplier_contacts, :is_decision_maker
  end
end