json.extract! account, :id, :code, :name, :sub_type, :account_type, :is_active, :deleted, :created_at, :updated_at
json.url account_url(account, format: :json)
