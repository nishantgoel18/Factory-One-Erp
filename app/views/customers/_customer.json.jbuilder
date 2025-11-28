json.extract! customer, :id, :code, :full_name, :email, :phone_number, :billing_address, :shipping_address, :is_active, :created_by_id, :deleted, :created_at, :updated_at
json.url customer_url(customer, format: :json)
