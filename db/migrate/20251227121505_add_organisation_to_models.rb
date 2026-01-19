class AddOrganisationToModels < ActiveRecord::Migration[8.1]
  def change
     # Products & Categories
    add_reference :products, :organization, foreign_key: true unless column_exists?(:products, :organization_id)
    add_reference :product_categories, :organization, foreign_key: true unless column_exists?(:product_categories, :organization_id)
    add_reference :unit_of_measures, :organization, foreign_key: true unless column_exists?(:unit_of_measures, :organization_id)
    add_reference :tax_codes, :organization, foreign_key: true unless column_exists?(:tax_codes, :organization_id)
    
    # Warehouses & Locations
    add_reference :warehouses, :organization, foreign_key: true unless column_exists?(:warehouses, :organization_id)
    add_reference :locations, :organization, foreign_key: true unless column_exists?(:locations, :organization_id)
    
    # BOM & Routing
    add_reference :bill_of_materials, :organization, foreign_key: true unless column_exists?(:bill_of_materials, :organization_id)
    add_reference :bom_items, :organization, foreign_key: true unless column_exists?(:bom_items, :organization_id)
    add_reference :work_centers, :organization, foreign_key: true unless column_exists?(:work_centers, :organization_id)
    add_reference :routings, :organization, foreign_key: true unless column_exists?(:routings, :organization_id)
    add_reference :routing_operations, :organization, foreign_key: true unless column_exists?(:routing_operations, :organization_id)
    
    # Work Orders
    add_reference :work_orders, :organization, foreign_key: true unless column_exists?(:work_orders, :organization_id)
    add_reference :work_order_operations, :organization, foreign_key: true unless column_exists?(:work_order_operations, :organization_id)
    add_reference :work_order_materials, :organization, foreign_key: true unless column_exists?(:work_order_materials, :organization_id)
    add_reference :labor_time_entries, :organization, foreign_key: true unless column_exists?(:labor_time_entries, :organization_id)
    
    # Customers
    add_reference :customers, :organization, foreign_key: true unless column_exists?(:customers, :organization_id)
    add_reference :customer_addresses, :organization, foreign_key: true unless column_exists?(:customer_addresses, :organization_id)
    add_reference :customer_contacts, :organization, foreign_key: true unless column_exists?(:customer_contacts, :organization_id)
    add_reference :customer_documents, :organization, foreign_key: true unless column_exists?(:customer_documents, :organization_id)
    add_reference :customer_activities, :organization, foreign_key: true unless column_exists?(:customer_activities, :organization_id)
    
    # Suppliers
    add_reference :suppliers, :organization, foreign_key: true unless column_exists?(:suppliers, :organization_id)
    add_reference :supplier_addresses, :organization, foreign_key: true unless column_exists?(:supplier_addresses, :organization_id)
    add_reference :supplier_contacts, :organization, foreign_key: true unless column_exists?(:supplier_contacts, :organization_id)
    add_reference :supplier_documents, :organization, foreign_key: true unless column_exists?(:supplier_documents, :organization_id)
    add_reference :supplier_activities, :organization, foreign_key: true unless column_exists?(:supplier_activities, :organization_id)
    add_reference :supplier_quality_issues, :organization, foreign_key: true unless column_exists?(:supplier_quality_issues, :organization_id)
    add_reference :supplier_performance_reviews, :organization, foreign_key: true unless column_exists?(:supplier_performance_reviews, :organization_id)
    add_reference :product_suppliers, :organization, foreign_key: true unless column_exists?(:product_suppliers, :organization_id)
    
    # RFQ & Procurement
    add_reference :rfqs, :organization, foreign_key: true unless column_exists?(:rfqs, :organization_id)
    add_reference :rfq_items, :organization, foreign_key: true unless column_exists?(:rfq_items, :organization_id)
    add_reference :rfq_suppliers, :organization, foreign_key: true unless column_exists?(:rfq_suppliers, :organization_id)
    add_reference :vendor_quotes, :organization, foreign_key: true unless column_exists?(:vendor_quotes, :organization_id)
    
    # Inventory
    add_reference :purchase_orders, :organization, foreign_key: true unless column_exists?(:purchase_orders, :organization_id)
    add_reference :purchase_order_lines, :organization, foreign_key: true unless column_exists?(:purchase_order_lines, :organization_id)
    add_reference :goods_receipts, :organization, foreign_key: true unless column_exists?(:goods_receipts, :organization_id)
    add_reference :goods_receipt_lines, :organization, foreign_key: true unless column_exists?(:goods_receipt_lines, :organization_id)
    add_reference :stock_issues, :organization, foreign_key: true unless column_exists?(:stock_issues, :organization_id)
    add_reference :stock_issue_lines, :organization, foreign_key: true unless column_exists?(:stock_issue_lines, :organization_id)
    add_reference :stock_transfers, :organization, foreign_key: true unless column_exists?(:stock_transfers, :organization_id)
    add_reference :stock_transfer_lines, :organization, foreign_key: true unless column_exists?(:stock_transfer_lines, :organization_id)
    add_reference :stock_adjustments, :organization, foreign_key: true unless column_exists?(:stock_adjustments, :organization_id)
    add_reference :stock_adjustment_lines, :organization, foreign_key: true unless column_exists?(:stock_adjustment_lines, :organization_id)
    add_reference :cycle_counts, :organization, foreign_key: true unless column_exists?(:cycle_counts, :organization_id)
    add_reference :stock_batches, :organization, foreign_key: true unless column_exists?(:stock_batches, :organization_id)
    add_reference :stock_levels, :organization, foreign_key: true unless column_exists?(:stock_levels, :organization_id)
    add_reference :stock_transactions, :organization, foreign_key: true unless column_exists?(:stock_transactions, :organization_id)
    
    # Accounting (if you have these)
    add_reference :accounts, :organization, foreign_key: true if table_exists?(:accounts) && !column_exists?(:accounts, :organization_id)
    add_reference :journal_entries, :organization, foreign_key: true if table_exists?(:journal_entries) && !column_exists?(:journal_entries, :organization_id)
    add_reference :journal_entry_lines, :organization, foreign_key: true if table_exists?(:journal_entry_lines) && !column_exists?(:journal_entry_lines, :organization_id)
  end
end
