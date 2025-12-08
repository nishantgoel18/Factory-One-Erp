# frozen_string_literal: true

# ============================================================================
# MIGRATION: Create Customer Activities Table
# ============================================================================
# Complete interaction tracking system - calls, emails, meetings, notes
# This is the CRM activity log for each customer
#
# Run: rails generate migration CreateCustomerActivities
# ============================================================================

class CreateCustomerActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_activities do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :customer, null: false, foreign_key: true, index: true
      t.references :customer_contact, foreign_key: true, index: true  # Which contact person
      t.references :related_user, foreign_key: { to_table: :users }, index: true  # Sales rep or user who performed activity
      
      # ========================================
      # ACTIVITY TYPE & STATUS
      # ========================================
      t.string :activity_type, limit: 30, null: false  # CALL, EMAIL, MEETING, NOTE, QUOTE, ORDER, COMPLAINT, VISIT, FOLLOWUP
      t.string :activity_status, limit: 20, default: "COMPLETED"  # SCHEDULED, COMPLETED, CANCELLED, OVERDUE
      t.string :subject, limit: 255, null: false
      t.text :description
      
      # ========================================
      # TIMING
      # ========================================
      t.datetime :activity_date, null: false  # When activity occurred or is scheduled
      t.integer :duration_minutes  # Length of call/meeting
      
      # ========================================
      # ACTIVITY DETAILS
      # ========================================
      t.string :outcome, limit: 50  # SUCCESS, NO_ANSWER, VOICEMAIL, RESCHEDULED, etc.
      t.string :next_action, limit: 255  # What needs to happen next
      t.datetime :followup_date  # When to follow up
      t.boolean :followup_required, default: false
      
      # ========================================
      # COMMUNICATION METHOD
      # ========================================
      t.string :communication_method, limit: 30  # PHONE, EMAIL, IN_PERSON, VIDEO_CALL, SMS, PORTAL
      t.string :direction, limit: 10  # INBOUND, OUTBOUND (for calls/emails)
      
      # ========================================
      # SENTIMENT & PRIORITY
      # ========================================
      t.string :customer_sentiment, limit: 20  # POSITIVE, NEUTRAL, NEGATIVE, URGENT
      t.string :priority, limit: 20, default: "NORMAL"  # LOW, NORMAL, HIGH, URGENT
      
      # ========================================
      # TAGS & CATEGORIZATION
      # ========================================
      t.string :tags, array: true, default: []  # PostgreSQL array for tags like ["pricing", "technical", "complaint"]
      t.string :category, limit: 50  # SALES, SUPPORT, BILLING, GENERAL
      
      # ========================================
      # LINKED ENTITIES (Optional)
      # ========================================
      t.string :related_entity_type  # For polymorphic association: SalesOrder, Quote, Invoice, etc.
      t.bigint :related_entity_id
      
      # ========================================
      # REMINDER SYSTEM
      # ========================================
      t.boolean :reminder_sent, default: false
      t.datetime :reminder_sent_at
      
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
    add_index :customer_activities, [:customer_id, :activity_date], order: { activity_date: :desc }
    add_index :customer_activities, [:customer_id, :activity_type]
    add_index :customer_activities, [:customer_id, :deleted]
    add_index :customer_activities, :activity_status
    add_index :customer_activities, :followup_date
    add_index :customer_activities, [:followup_date, :followup_required], name: 'index_customer_activities_on_followup'
    add_index :customer_activities, [:related_entity_type, :related_entity_id], name: 'index_customer_activities_on_related_entity'
    add_index :customer_activities, :priority
    add_index :customer_activities, :customer_sentiment
    add_index :customer_activities, :tags, using: :gin  # GIN index for array search
  end
end