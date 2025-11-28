class CreateTaxCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_codes do |t|
      t.string  :code, limit: 20
      t.string  :name
      t.string  :jurisdiction
      t.string  :tax_type

      t.string  :country, default: "US"
      t.string  :state_province
      t.string  :county
      t.string  :city

      t.decimal :rate, precision: 6, scale: 4, default: 0
      t.boolean :is_compound, default: false
      t.string  :compounds_on

      t.date    :effective_from
      t.date    :effective_to

      t.string  :tax_authority_id
      t.string  :filing_frequency, default: "MONTHLY"

      t.boolean :is_active, default: true
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :tax_codes, :code, unique: true
  end
end