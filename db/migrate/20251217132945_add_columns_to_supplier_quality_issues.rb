class AddColumnsToSupplierQualityIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_quality_issues, :related_po_number, :string
    add_column :supplier_quality_issues, :lot_batch_number, :string
    add_column :supplier_quality_issues, :root_cause_category, :string
    add_column :supplier_quality_issues, :expected_resolution_date, :date
    add_column :supplier_quality_issues, :supplier_notified, :boolean


  end
end
