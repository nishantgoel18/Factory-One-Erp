class AddColumnsToSupplierDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_documents, :issuing_authority, :text
    add_column :supplier_documents, :renewal_date, :date
    add_column :supplier_documents, :document_number, :string
    add_column :supplier_documents, :file, :string

  end
end
