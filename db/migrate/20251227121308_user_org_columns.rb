class UserOrgColumns < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organization, null: true, foreign_key: true
    add_column :users, :role, :integer, default: 0
    add_column :users, :phone_number, :string
    
    # Update existing unique index on email to scope by organization
    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, [:organization_id, :email], unique: true
  end
end
