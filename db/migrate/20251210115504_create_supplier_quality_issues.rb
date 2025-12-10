class CreateSupplierQualityIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_quality_issues do |t|
      # Foreign Keys
      t.references :supplier, null: false, foreign_key: true, index: true
      t.references :product, foreign_key: true, index: true # Optional - specific product
      # t.references :purchase_order, foreign_key: true, index: true # Will add when PO module exists
      # t.references :purchase_order_line, foreign_key: true # Will add when PO module exists
      
      # Issue Details
      t.string :issue_number # Auto-generated: QI-00001
      t.string :issue_title, null: false
      t.text :issue_description, null: false
      t.string :issue_type # DEFECT, NON_CONFORMANCE, SHORT_SHIPMENT, WRONG_ITEM, DAMAGE, CONTAMINATION, OTHER
      t.string :severity, null: false # CRITICAL, MAJOR, MINOR
      t.date :issue_date, null: false
      t.date :detected_date
      
      # Quantity Impact
      t.decimal :quantity_affected, precision: 15, scale: 2
      t.decimal :quantity_rejected, precision: 15, scale: 2
      t.decimal :quantity_reworked, precision: 15, scale: 2
      t.decimal :quantity_returned, precision: 15, scale: 2
      
      # Financial Impact
      t.decimal :financial_impact, precision: 15, scale: 2 # Cost of issue
      t.boolean :credit_requested, default: false
      t.decimal :credit_amount, precision: 15, scale: 2
      t.boolean :credit_issued, default: false
      t.date :credit_issued_date
      
      # Status & Resolution
      t.string :status, default: 'OPEN' # OPEN, IN_PROGRESS, RESOLVED, CLOSED, RECURRING
      t.text :root_cause_analysis
      t.text :corrective_action_taken
      t.text :preventive_action_taken
      t.date :resolution_date
      t.date :closed_date
      t.integer :days_to_resolve
      
      # Supplier Response
      t.date :supplier_notified_date
      t.text :supplier_response
      t.date :supplier_response_date
      t.integer :supplier_response_time_days
      t.boolean :supplier_acknowledged, default: false
      
      # Impact on Rating
      t.decimal :rating_impact_points, precision: 5, scale: 2 # Deduction from overall rating
      t.boolean :impacts_supplier_rating, default: true
      
      # Recurrence Tracking
      t.boolean :is_repeat_issue, default: false
      t.references :related_issue, foreign_key: { to_table: :supplier_quality_issues }
      t.integer :occurrence_count, default: 1
      
      # Follow-up
      t.boolean :requires_audit, default: false
      t.date :audit_scheduled_date
      t.date :audit_completed_date
      t.boolean :requires_corrective_action_verification, default: false
      t.date :verification_due_date
      t.date :verification_completed_date
      
      # Attachments Info
      t.text :attachments_description # What photos/docs are attached
      
      # Internal Notes
      t.text :quality_team_notes
      t.text :purchasing_team_notes
      
      # Audit
      t.references :reported_by, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :supplier_quality_issues, :issue_number, unique: true
    add_index :supplier_quality_issues, :issue_date
    add_index :supplier_quality_issues, :status
    add_index :supplier_quality_issues, :severity
    add_index :supplier_quality_issues, [:supplier_id, :status]
    add_index :supplier_quality_issues, [:product_id, :status]
    add_index :supplier_quality_issues, :is_repeat_issue
  end
end
