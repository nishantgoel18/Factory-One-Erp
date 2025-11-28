class AddReversalFieldsToJournalEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :journal_entries, :reversed, :boolean, default: false
    add_column :journal_entries, :reversed_at, :datetime
    add_column :journal_entries, :reversal_entry_id, :integer
  end
end
