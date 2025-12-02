class CreateStockIssueLines < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_issue_lines do |t|
      t.references :stock_issue, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :stock_batch, null: false, foreign_key: true
      t.integer :from_location_id, null: false
      t.decimal :quantity
      t.boolean :deleted

      t.timestamps
    end
    add_index :stock_issue_lines, :from_location_id
  end
end
