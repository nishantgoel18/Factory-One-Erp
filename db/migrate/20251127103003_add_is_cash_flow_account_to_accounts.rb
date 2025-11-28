class AddIsCashFlowAccountToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :is_cash_flow_account, :boolean, default: false
  end
end
