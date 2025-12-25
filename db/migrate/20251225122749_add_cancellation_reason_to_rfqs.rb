class AddCancellationReasonToRfqs < ActiveRecord::Migration[8.1]
  def change
    add_column :rfqs, :cancellation_reason, :text
  end
end
