class AddDeletedToJournalLine < ActiveRecord::Migration[8.1]
  def change
    add_column :journal_lines, :deleted, :boolean, default: false
  end
end
