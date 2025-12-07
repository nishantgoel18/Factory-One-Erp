class AddLocationTypeLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :location_type, :string, default: 'GENERAL'
    add_index :locations, :location_type
  end
end
