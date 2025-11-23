json.extract! warehouse, :id, :name, :code, :address, :is_active, :deleted, :created_at, :updated_at
json.url warehouse_url(warehouse, format: :json)
