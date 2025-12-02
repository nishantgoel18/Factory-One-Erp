class AddPostedByToStockIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_issues, :posted_by, :integer
    add_index :stock_issues, :posted_by
  end
end
