require "test_helper"

class StockIssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @stock_issue = stock_issues(:one)
  end

  test "should get index" do
    get stock_issues_url
    assert_response :success
  end

  test "should get new" do
    get new_stock_issue_url
    assert_response :success
  end

  test "should create stock_issue" do
    assert_difference("StockIssue.count") do
      post stock_issues_url, params: { stock_issue: { created_by: @stock_issue.created_by, deleted: @stock_issue.deleted, reference_no: @stock_issue.reference_no, status: @stock_issue.status, warehouse_id: @stock_issue.warehouse_id } }
    end

    assert_redirected_to stock_issue_url(StockIssue.last)
  end

  test "should show stock_issue" do
    get stock_issue_url(@stock_issue)
    assert_response :success
  end

  test "should get edit" do
    get edit_stock_issue_url(@stock_issue)
    assert_response :success
  end

  test "should update stock_issue" do
    patch stock_issue_url(@stock_issue), params: { stock_issue: { created_by: @stock_issue.created_by, deleted: @stock_issue.deleted, reference_no: @stock_issue.reference_no, status: @stock_issue.status, warehouse_id: @stock_issue.warehouse_id } }
    assert_redirected_to stock_issue_url(@stock_issue)
  end

  test "should destroy stock_issue" do
    assert_difference("StockIssue.count", -1) do
      delete stock_issue_url(@stock_issue)
    end

    assert_redirected_to stock_issues_url
  end
end
