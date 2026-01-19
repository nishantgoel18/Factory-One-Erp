class CreateOrganisations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :industry
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :name
    add_index :organizations, :active
  end
end
