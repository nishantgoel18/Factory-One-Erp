class CreateStockIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_issues do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.string :status
      t.string :reference_no
      t.integer :created_by
      t.boolean :deleted

      t.timestamps
    end
  end
end
