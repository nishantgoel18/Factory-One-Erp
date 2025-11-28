class AddIsStockedToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :is_stocked, :boolean
  end
end
