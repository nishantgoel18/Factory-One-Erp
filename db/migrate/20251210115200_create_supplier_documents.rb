class CreateSupplierDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_documents do |t|
      # Foreign Key
      t.references :supplier, null: false, foreign_key: true, index: true
      
      # Document Type & Classification
      t.string :document_type, null: false # CONTRACT, QUALITY_AGREEMENT, NDA, INSURANCE_CERT, ISO_CERT, W9, SDS, TEST_REPORT, AUDIT_REPORT, OTHER
      t.string :document_category # LEGAL, QUALITY, COMPLIANCE, TECHNICAL, FINANCIAL
      t.string :document_title, null: false
      t.text :description
      
      # File Attachment (via ActiveStorage)
      # Will use: has_one_attached :file
      t.string :file_name
      t.integer :file_size
      t.string :file_content_type
      
      # Validity Dates
      t.date :effective_date
      t.date :expiry_date
      t.boolean :requires_renewal, default: false
      t.integer :renewal_reminder_days, default: 30
      
      # Version Control
      t.integer :version, default: 1
      t.references :superseded_by, foreign_key: { to_table: :supplier_documents }
      
      # Access Control
      t.boolean :is_confidential, default: false
      t.boolean :supplier_can_view, default: false
      
      # Status
      t.boolean :is_active, default: true
      
      # Notes
      t.text :notes
      
      # Audit
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :supplier_documents, :document_type
    add_index :supplier_documents, :expiry_date
    add_index :supplier_documents, :is_active
    add_index :supplier_documents, [:supplier_id, :document_type]
  end
end
