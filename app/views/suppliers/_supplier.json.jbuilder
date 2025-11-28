json.extract! supplier, :id, :code, :name, :email, :phone, :billing_address, :shipping_address, :lead_time_days, :on_time_delivery_rate, :is_active, :deleted, :created_by, :created_at, :updated_at
json.url supplier_url(supplier, format: :json)
