class CreateUnitOfMeasures < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_of_measures do |t|
      t.string :name
      t.string :symbol
      t.boolean :is_decimal

      t.timestamps
    end
  end
end
