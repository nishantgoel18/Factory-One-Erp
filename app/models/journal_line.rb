class JournalLine < ApplicationRecord
  belongs_to :journal_entry
  belongs_to :account

  validates :account_id, presence: true
  validates :debit, numericality: { greater_than_or_equal_to: 0 }
  validates :credit, numericality: { greater_than_or_equal_to: 0 }

  validate :cannot_have_both_debit_and_credit

  def cannot_have_both_debit_and_credit
    if debit.to_d > 0 && credit.to_d > 0
      errors.add(:base, "A line cannot have both debit and credit.")
    end

    if debit.to_d == 0 && credit.to_d == 0
      errors.add(:base, "Either debit or credit must be entered.")
    end
  end
end