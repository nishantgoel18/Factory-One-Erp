class AddAwardedAtToRfqItems < ActiveRecord::Migration[8.1]
  def change
    add_column :rfq_items, :awarded_at, :datetime
  end
end
