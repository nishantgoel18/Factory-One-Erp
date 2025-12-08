require "test_helper"

class TaxCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tax_code = tax_codes(:one)
  end

  test "should get index" do
    get tax_codes_url
    assert_response :success
  end

  test "should get new" do
    get new_tax_code_url
    assert_response :success
  end

  test "should create tax_code" do
    assert_difference("TaxCode.count") do
      post tax_codes_url, params: { tax_code: { city: @tax_code.city, code: @tax_code.code, compounds_on: @tax_code.compounds_on, country: @tax_code.country, county: @tax_code.county, deleted: @tax_code.deleted, effective_from: @tax_code.effective_from, effective_to: @tax_code.effective_to, filing_frequency: @tax_code.filing_frequency, is_active: @tax_code.is_active, is_compound: @tax_code.is_compound, jurisdiction: @tax_code.jurisdiction, name: @tax_code.name, rate: @tax_code.rate, state_province: @tax_code.state_province, tax_authority_id: @tax_code.tax_authority_id, tax_type: @tax_code.tax_type } }
    end

    assert_redirected_to tax_code_url(TaxCode.last)
  end

  test "should show tax_code" do
    get tax_code_url(@tax_code)
    assert_response :success
  end

  test "should get edit" do
    get edit_tax_code_url(@tax_code)
    assert_response :success
  end

  test "should update tax_code" do
    patch tax_code_url(@tax_code), params: { tax_code: { city: @tax_code.city, code: @tax_code.code, compounds_on: @tax_code.compounds_on, country: @tax_code.country, county: @tax_code.county, deleted: @tax_code.deleted, effective_from: @tax_code.effective_from, effective_to: @tax_code.effective_to, filing_frequency: @tax_code.filing_frequency, is_active: @tax_code.is_active, is_compound: @tax_code.is_compound, jurisdiction: @tax_code.jurisdiction, name: @tax_code.name, rate: @tax_code.rate, state_province: @tax_code.state_province, tax_authority_id: @tax_code.tax_authority_id, tax_type: @tax_code.tax_type } }
    assert_redirected_to tax_code_url(@tax_code)
  end

  test "should destroy tax_code" do
    assert_difference("TaxCode.count", -1) do
      delete tax_code_url(@tax_code)
    end

    assert_redirected_to tax_codes_url
  end
end
