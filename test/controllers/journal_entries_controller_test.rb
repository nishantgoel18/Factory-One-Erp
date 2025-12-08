require "test_helper"

class JournalEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @journal_entry = journal_entries(:one)
  end

  test "should get index" do
    get journal_entries_url
    assert_response :success
  end

  test "should get new" do
    get new_journal_entry_url
    assert_response :success
  end

  test "should create journal_entry" do
    assert_difference("JournalEntry.count") do
      post journal_entries_url, params: { journal_entry: { accounting_period: @journal_entry.accounting_period, deleted: @journal_entry.deleted, description: @journal_entry.description, entry_date: @journal_entry.entry_date, entry_number: @journal_entry.entry_number, posted_at: @journal_entry.posted_at, posted_by: @journal_entry.posted_by, reference_id: @journal_entry.reference_id, reference_type: @journal_entry.reference_type, total_credit: @journal_entry.total_credit, total_debit: @journal_entry.total_debit } }
    end

    assert_redirected_to journal_entry_url(JournalEntry.last)
  end

  test "should show journal_entry" do
    get journal_entry_url(@journal_entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_journal_entry_url(@journal_entry)
    assert_response :success
  end

  test "should update journal_entry" do
    patch journal_entry_url(@journal_entry), params: { journal_entry: { accounting_period: @journal_entry.accounting_period, deleted: @journal_entry.deleted, description: @journal_entry.description, entry_date: @journal_entry.entry_date, entry_number: @journal_entry.entry_number, posted_at: @journal_entry.posted_at, posted_by: @journal_entry.posted_by, reference_id: @journal_entry.reference_id, reference_type: @journal_entry.reference_type, total_credit: @journal_entry.total_credit, total_debit: @journal_entry.total_debit } }
    assert_redirected_to journal_entry_url(@journal_entry)
  end

  test "should destroy journal_entry" do
    assert_difference("JournalEntry.count", -1) do
      delete journal_entry_url(@journal_entry)
    end

    assert_redirected_to journal_entries_url
  end
end
