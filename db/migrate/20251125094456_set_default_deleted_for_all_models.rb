class SetDefaultDeletedForAllModels < ActiveRecord::Migration[7.0]
  def change
    change_column_default :products, :deleted, false
    change_column_default :product_categories, :deleted, false
    change_column_default :warehouses, :deleted, false
    change_column_default :locations, :deleted, false
    # change_column_default :unit_of_measures, :deleted, false
  end
end