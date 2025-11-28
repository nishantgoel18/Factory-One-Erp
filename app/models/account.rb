class Account < ApplicationRecord
    attr_accessor :current_balance
    ACCOUNT_TYPE_CHOICES = {
        "INCOME"   => "Income",
        "EXPENSE"  => "Expense",
        "ASSET"    => "Asset",
        "LIABILITY"=> "Liability",
        "EQUITY"   => "Equity",
        "COGS"     => "Cost of Goods Sold",
        "INVENTORY" => "Inventory",
        "GRIR"     => "GR/IR"
    }

    SUB_TYPE_CHOICES = {
        "MATERIAL_COST" => "Material Cost",
        "LABOR_COST"    => "Labor Cost",
        "OVERHEAD_COST" => "Overhead",
        "SALES_REVENUE" => "Sales Revenue",
        "OTHER"         => "Other"
    }

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :account_type, presence: true
    validates :sub_type, presence: true

    def self.debit_increase_account_types
        ['ASSET', 'EXPENSE', 'COGS', 'INVENTORY']
    end

    def self.debit_increase_account_types
        ['LIABILITY', 'EQUITY', 'INCOME', 'GRIR']
    end
end
