class AddDeletedToUnitOfMeasures < ActiveRecord::Migration[8.1]
  def change
    add_column :unit_of_measures, :deleted, :boolean
  end
end
