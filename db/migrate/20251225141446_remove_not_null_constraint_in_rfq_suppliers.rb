class RemoveNotNullConstraintInRfqSuppliers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :rfq_suppliers, :invited_at, true
  end
end
