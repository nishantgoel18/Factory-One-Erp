class AddCreatedByIdToStockIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_issues, :created_by_id, :integer
    add_index :stock_issues, :created_by_id
  end
end
