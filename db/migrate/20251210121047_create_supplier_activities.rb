class CreateSupplierActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_activities do |t|
      # Foreign Keys
      t.references :supplier, null: false, foreign_key: true, index: true
      t.references :supplier_contact, foreign_key: true, index: true # Optional - which contact
      t.references :related_user, foreign_key: { to_table: :users } # Our team member who had interaction
      
      # Activity Details
      t.string :activity_type, null: false # CALL, EMAIL, MEETING, VISIT, RFQ, QUOTE, NEGOTIATION, AUDIT, ISSUE_RESOLUTION, NOTE, OTHER
      t.string :activity_status, default: 'COMPLETED' # SCHEDULED, COMPLETED, CANCELLED, OVERDUE
      t.string :subject, null: false
      t.text :description
      
      # Timing
      t.datetime :activity_date, null: false
      t.integer :duration_minutes
      
      # Outcome & Follow-up
      t.text :outcome
      t.text :action_items
      t.text :next_steps
      t.boolean :followup_required, default: false
      t.date :followup_date
      t.boolean :is_overdue, default: false
      
      # Communication Details
      t.string :communication_method # PHONE, EMAIL, IN_PERSON, VIDEO_CALL, SMS
      t.string :direction # INBOUND, OUTBOUND
      
      # Sentiment & Priority
      t.string :supplier_sentiment # POSITIVE, NEUTRAL, NEGATIVE, URGENT
      t.string :priority, default: 'NORMAL' # LOW, NORMAL, HIGH, URGENT
      
      # Classification
      t.string :category # RFQ, QUOTE_REVIEW, PRICE_NEGOTIATION, QUALITY_DISCUSSION, DELIVERY_ISSUE, PAYMENT, GENERAL
      t.text :tags # Array of tags
      
      # Related Records (polymorphic - can link to POs, RFQs, Quality Issues, etc.)
      t.references :related_record, polymorphic: true, index: true
      
      # Attachments Info
      t.text :attachments_description
      
      # Audit
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :supplier_activities, :activity_type
    add_index :supplier_activities, :activity_status
    add_index :supplier_activities, :activity_date
    add_index :supplier_activities, [:supplier_id, :activity_type]
    add_index :supplier_activities, [:supplier_id, :activity_date]
    add_index :supplier_activities, :followup_date
    add_index :supplier_activities, :is_overdue
  end
end
