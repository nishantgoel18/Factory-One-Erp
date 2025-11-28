json.extract! location, :id, :warehouse_id, :code, :name, :is_pickable, :is_receivable, :deleted, :created_at, :updated_at
json.url location_url(location, format: :json)
