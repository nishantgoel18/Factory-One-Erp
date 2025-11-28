class AddIsReversalToJournalEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :journal_entries, :is_reversal, :boolean, default: false
  end
end
