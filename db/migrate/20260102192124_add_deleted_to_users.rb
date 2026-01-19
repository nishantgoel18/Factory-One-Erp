class AddDeletedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :deleted, :boolean, default: false
  end
end
