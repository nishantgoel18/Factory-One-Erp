json.extract! product, :id, :sku, :name, :product_category_id, :unit_of_measure_id, :is_batch_tracked, :is_serial_tracked, :reorder_point, :is_active, :deleted, :created_at, :updated_at
json.url product_url(product, format: :json)
