class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.string :entry_number
      t.date :entry_date
      t.string :reference_type
      t.string :reference_id
      t.text :description
      t.decimal :total_debit
      t.decimal :total_credit
      t.integer :posted_by
      t.datetime :posted_at
      t.boolean :deleted
      t.string :accounting_period

      t.timestamps
    end
    add_index :journal_entries, :posted_by
  end
end
