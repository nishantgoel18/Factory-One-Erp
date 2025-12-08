class CreateCustomerDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_documents do |t|
      # ========================================
      # ASSOCIATIONS
      # ========================================
      t.references :customer, null: false, foreign_key: true, index: true
      
      # ========================================
      # DOCUMENT CLASSIFICATION
      # ========================================
      t.string :document_type, limit: 50, null: false  # CONTRACT, TAX_CERT, NDA, CREDIT_APP, QUALITY_AGREEMENT, OTHER
      t.string :document_category, limit: 50  # LEGAL, FINANCIAL, QUALITY, COMPLIANCE, GENERAL
      t.string :document_title, limit: 255, null: false
      t.text :description
      
      # ========================================
      # FILE INFORMATION
      # ========================================
      # Note: Actual files stored via ActiveStorage
      # This just tracks metadata
      t.string :file_name, limit: 255
      t.string :file_type, limit: 50  # PDF, DOCX, XLSX, JPG, etc.
      t.integer :file_size  # in bytes
      t.string :file_url, limit: 500  # If stored externally or S3 URL
      
      # ========================================
      # DOCUMENT STATUS & VALIDITY
      # ========================================
      t.boolean :is_active, default: true
      t.date :effective_date
      t.date :expiry_date
      t.boolean :requires_renewal, default: false
      t.integer :renewal_reminder_days, default: 30  # Alert X days before expiry
      
      # ========================================
      # VERSION CONTROL
      # ========================================
      t.string :version, limit: 20, default: "1.0"
      t.boolean :is_latest_version, default: true
      t.references :superseded_by, foreign_key: { to_table: :customer_documents }, index: true
      
      # ========================================
      # ACCESS CONTROL
      # ========================================
      t.boolean :is_confidential, default: false
      t.boolean :customer_can_view, default: false  # If customer portal exists
      
      # ========================================
      # AUDIT FIELDS
      # ========================================
      t.boolean :deleted, default: false, null: false
      t.references :uploaded_by, foreign_key: { to_table: :users }, index: true
      t.text :notes
      
      t.timestamps
    end
    
    # ========================================
    # INDEXES
    # ========================================
    add_index :customer_documents, [:customer_id, :document_type]
    add_index :customer_documents, [:customer_id, :deleted]
    add_index :customer_documents, :expiry_date
    add_index :customer_documents, :is_active
    add_index :customer_documents, [:expiry_date, :requires_renewal], name: 'index_customer_docs_on_expiry_and_renewal'
  end
end
