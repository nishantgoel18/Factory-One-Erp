json.extract! tax_code, :id, :code, :name, :jurisdiction, :tax_type, :country, :state_province, :county, :city, :rate, :is_compound, :compounds_on, :effective_from, :effective_to, :tax_authority_id, :filing_frequency, :is_active, :deleted, :created_at, :updated_at
json.url tax_code_url(tax_code, format: :json)
