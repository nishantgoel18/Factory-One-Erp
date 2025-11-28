class CreateBillOfMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_of_materials do |t|
      t.references :product, foreign_key: true
      t.string :code
      t.string :name
      t.string :revision
      t.string :status, default: "DRAFT"
      t.date :effective_from
      t.date :effective_to
      t.boolean :is_default, default: false
      t.text :notes
      t.integer :created_by
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :bill_of_materials, :code, unique: true
  end
end