class CreateOrganisationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_settings do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      
      # Company Information
      t.string :company_name
      t.string :legal_name
      t.string :tax_id
      t.text :primary_address
      
      # Regional Settings
      t.string :country, default: 'US'
      t.string :currency, default: 'USD'
      t.string :time_zone, default: 'America/New_York'
      t.string :date_format, default: 'MM/DD/YYYY'
      t.string :number_format, default: '1,234.56'
      
      # Fiscal Settings
      t.integer :fiscal_year_start_month, default: 1
      t.decimal :working_hours_per_day, precision: 4, scale: 2, default: 8.0
      t.string :working_days, array: true, default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
      
      # Holiday Calendar (JSONB for flexibility)
      t.jsonb :holiday_list, default: []
      
      t.timestamps
    end
  end
end
