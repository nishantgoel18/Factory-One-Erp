class CreateBomItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bom_items do |t|
      t.references :bill_of_materials, foreign_key: true
      t.references :component, foreign_key: { to_table: :products }
      t.decimal :quantity, precision: 14, scale: 4, default: 0
      t.references :uom, foreign_key: { to_table: :unit_of_measures }
      t.decimal :scrap_percent, precision: 5, scale: 2, default: 0
      t.text :line_note
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
