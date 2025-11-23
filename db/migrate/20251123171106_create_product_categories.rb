class CreateProductCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :product_categories do |t|
      t.string :name
      t.integer :parent_id
      t.boolean :deleted

      t.timestamps
    end
    add_index :product_categories, :parent_id
  end
end
