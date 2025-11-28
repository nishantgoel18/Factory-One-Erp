class RenameBillOfMaterialsIdToBillOfMaterialIdInBomItems < ActiveRecord::Migration[8.1]
  def change
    rename_column :bom_items, :bill_of_materials_id, :bill_of_material_id
  end
end
