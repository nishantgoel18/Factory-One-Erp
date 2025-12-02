class AddPostedAtToStockIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_issues, :posted_at, :datetime
  end
end
