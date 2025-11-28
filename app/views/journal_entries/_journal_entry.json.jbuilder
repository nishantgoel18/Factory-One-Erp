json.extract! journal_entry, :id, :entry_number, :entry_date, :reference_type, :reference_id, :description, :total_debit, :total_credit, :posted_by, :posted_at, :deleted, :accounting_period, :created_at, :updated_at
json.url journal_entry_url(journal_entry, format: :json)
