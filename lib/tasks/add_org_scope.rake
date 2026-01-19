# lib/tasks/add_org_scope.rake

namespace :org do
  desc "Add OrganizationScoped concern to all business models"
  task add_scope: :environment do
    # List of all your business models
    models = [
      # Core Master Data
      'Product',
      'ProductCategory',
      'UnitOfMeasure',
      'TaxCode',
      
      # Warehouse
      'Warehouse',
      'Location',
      
      # BOM & Routing
      'BillOfMaterial',
      'BomItem',
      'WorkCenter',
      'Routing',
      'RoutingOperation',
      
      # Work Orders
      'WorkOrder',
      'WorkOrderOperation',
      'WorkOrderMaterial',
      'LaborTimeEntry',
      
      # Customers
      'Customer',
      'CustomerAddress',
      'CustomerContact',
      'CustomerDocument',
      'CustomerActivity',
      
      # Suppliers
      'Supplier',
      'SupplierAddress',
      'SupplierContact',
      'SupplierDocument',
      'SupplierActivity',
      'SupplierQualityIssue',
      'SupplierPerformanceReview',
      'ProductSupplier',
      
      # RFQ
      'Rfq',
      'RfqItem',
      'RfqSupplier',
      'VendorQuote',
      
      # Inventory
      'PurchaseOrder',
      'PurchaseOrderLine',
      'Inventory::GoodsReceipt',
      'Inventory::GoodsReceiptLine',
      'Inventory::StockIssue',
      'Inventory::StockIssueLine',
      'Inventory::StockTransfer',
      'Inventory::StockTransferLine',
      'Inventory::StockAdjustment',
      'Inventory::StockAdjustmentLine',
      'Inventory::CycleCount',
      'Inventory::CycleCountLine',
      'Inventory::StockBatch',
      'Inventory::StockLevel',
      'Inventory::StockTransaction',
      
      # Accounting
      'Account',
      'JournalEntry',
      'JournalEntryLine'
    ]
    
    puts "🚀 Adding OrganizationScoped to #{models.count} models..."
    
    models.each do |model_name|
      model_file = "app/models/#{model_name.underscore}.rb"
      
      next unless File.exist?(model_file)
      
      content = File.read(model_file)
      
      # Check if already included
      if content.include?('include OrganizationScoped')
        puts "  ⏭️  #{model_name} - Already has OrganizationScoped"
        next
      end
      
      # Find the class definition line
      class_line_regex = /class #{model_name.split('::').last} < ApplicationRecord/
      
      if content =~ class_line_regex
        # Add the include right after class definition
        updated_content = content.sub(class_line_regex) do |match|
          "#{match}\n  include OrganizationScoped"
        end
        
        File.write(model_file, updated_content)
        puts "  ✅ #{model_name} - OrganizationScoped added!"
      else
        puts "  ⚠️  #{model_name} - Could not find class definition"
      end
    end
    
    puts "\n✨ Done! Run 'rails db:migrate' to add organization_id columns."
  end
end