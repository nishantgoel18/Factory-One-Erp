class AddStandardCostToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :standard_cost, :decimal
  end
end
