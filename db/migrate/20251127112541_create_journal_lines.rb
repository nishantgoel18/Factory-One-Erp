class CreateJournalLines < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_lines do |t|
      t.integer :account_id
      t.integer :journal_entry_id
      t.text :description
      t.decimal :debit, default: 0
      t.decimal :credit, default: 0

      t.timestamps
    end
    add_index :journal_lines, :account_id
    add_index :journal_lines, :journal_entry_id
  end
end
