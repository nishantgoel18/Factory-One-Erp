require "test_helper"

class UnitOfMeasuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unit_of_measure = unit_of_measures(:one)
  end

  test "should get index" do
    get unit_of_measures_url
    assert_response :success
  end

  test "should get new" do
    get new_unit_of_measure_url
    assert_response :success
  end

  test "should create unit_of_measure" do
    assert_difference("UnitOfMeasure.count") do
      post unit_of_measures_url, params: { unit_of_measure: { is_decimal: @unit_of_measure.is_decimal, name: @unit_of_measure.name, symbol: @unit_of_measure.symbol } }
    end

    assert_redirected_to unit_of_measure_url(UnitOfMeasure.last)
  end

  test "should show unit_of_measure" do
    get unit_of_measure_url(@unit_of_measure)
    assert_response :success
  end

  test "should get edit" do
    get edit_unit_of_measure_url(@unit_of_measure)
    assert_response :success
  end

  test "should update unit_of_measure" do
    patch unit_of_measure_url(@unit_of_measure), params: { unit_of_measure: { is_decimal: @unit_of_measure.is_decimal, name: @unit_of_measure.name, symbol: @unit_of_measure.symbol } }
    assert_redirected_to unit_of_measure_url(@unit_of_measure)
  end

  test "should destroy unit_of_measure" do
    assert_difference("UnitOfMeasure.count", -1) do
      delete unit_of_measure_url(@unit_of_measure)
    end

    assert_redirected_to unit_of_measures_url
  end
end
