class AddProductTypeToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :product_type, :string
  end
end
