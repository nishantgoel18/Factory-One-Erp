class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.string :code
      t.string :name
      t.boolean :is_pickable
      t.boolean :is_receivable
      t.boolean :deleted

      t.timestamps
    end
  end
end
