class AddOperatorAssignmentWorkOrderOperations < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_operations, :assigned_operator_id, :bigint
    add_column :work_order_operations, :assigned_at, :datetime
    add_column :work_order_operations, :assigned_by_id, :bigint
    
    add_index :work_order_operations, :assigned_operator_id
    add_index :work_order_operations, :assigned_at
  end
end
