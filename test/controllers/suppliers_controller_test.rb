require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = suppliers(:one)
  end

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should get new" do
    get new_supplier_url
    assert_response :success
  end

  test "should create supplier" do
    assert_difference("Supplier.count") do
      post suppliers_url, params: { supplier: { billing_address: @supplier.billing_address, code: @supplier.code, created_by: @supplier.created_by, deleted: @supplier.deleted, email: @supplier.email, is_active: @supplier.is_active, lead_time_days: @supplier.lead_time_days, name: @supplier.name, on_time_delivery_rate: @supplier.on_time_delivery_rate, phone: @supplier.phone, shipping_address: @supplier.shipping_address } }
    end

    assert_redirected_to supplier_url(Supplier.last)
  end

  test "should show supplier" do
    get supplier_url(@supplier)
    assert_response :success
  end

  test "should get edit" do
    get edit_supplier_url(@supplier)
    assert_response :success
  end

  test "should update supplier" do
    patch supplier_url(@supplier), params: { supplier: { billing_address: @supplier.billing_address, code: @supplier.code, created_by: @supplier.created_by, deleted: @supplier.deleted, email: @supplier.email, is_active: @supplier.is_active, lead_time_days: @supplier.lead_time_days, name: @supplier.name, on_time_delivery_rate: @supplier.on_time_delivery_rate, phone: @supplier.phone, shipping_address: @supplier.shipping_address } }
    assert_redirected_to supplier_url(@supplier)
  end

  test "should destroy supplier" do
    assert_difference("Supplier.count", -1) do
      delete supplier_url(@supplier)
    end

    assert_redirected_to suppliers_url
  end
end
