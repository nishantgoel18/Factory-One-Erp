class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :code
      t.string :name
      t.string :sub_type
      t.string :account_type
      t.boolean :is_active, default: false
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
