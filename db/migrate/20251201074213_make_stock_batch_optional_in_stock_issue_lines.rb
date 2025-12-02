class MakeStockBatchOptionalInStockIssueLines < ActiveRecord::Migration[8.1]
  def change
    change_column_null :stock_issue_lines, :stock_batch_id, true
  end
end
