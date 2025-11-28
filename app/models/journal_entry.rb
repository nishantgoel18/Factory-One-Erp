class JournalEntry < ApplicationRecord
	REF_TYPE_CHOICES = {
        'PO' => "Purchase Order",
        'GRN' => "Goods Receipt Note",
        'SO' => "Sales Order",
        'SHIPMENT' => "Shipment",
        'WO' => "Work Order",
        'ADJUSTMENT' => "Adjustment",
    }


	has_many :journal_lines, dependent: :destroy
	belongs_to :posted_by_user, class_name: "User", foreign_key: "posted_by", optional: true

	accepts_nested_attributes_for :journal_lines, allow_destroy: true

	validates :entry_date, presence: true
	# validates :entry_number, presence: true, uniqueness: true
	validates :reference_type, inclusion: { in: REF_TYPE_CHOICES.keys }, allow_nil: true, allow_blank: true

	validate :must_balance
  	validate :must_have_lines

  	before_create :generate_entry_number

  	def must_have_lines

    	if journal_lines.select{|je| !je.deleted? }.reject(&:marked_for_destruction?).size < 1
      		errors.add(:base, "At least one line is required.")
    	end
  	end

  	def must_balance
    	debits = journal_lines.select{|je| !je.deleted? }.sum(&:debit)
    	credits = journal_lines.select{|je| !je.deleted? }.sum(&:credit)

    	if debits != credits
      		errors.add(:base, "Debits and credits must be equal.")
    	end
  	end

  	def generate_entry_number
    	self.entry_number ||= "JE-#{Time.now.strftime("%Y%m%d")}-#{SecureRandom.hex(2).upcase}"
  	end

  	def post!(user)
    	return "Journal entry already posted." if posted_at.present?
    	if journal_lines.select{|je| !je.deleted? }.sum(&:debit) != journal_lines.select{|je| !je.deleted? }.sum(&:credit)
      		return "Journal entry must be balanced."
    	end

    	transaction do
      		update!(posted_at: Time.current, posted_by: user.id)

      		journal_lines.select{|je| !je.deleted? }.each do |line|
        		account = line.account
        		debit  = line.debit.to_d
        		credit = line.credit.to_d

        		if %w[ASSET EXPENSE COGS INVENTORY].include?(account.account_type)
          			new_balance = account.current_balance.to_d + (debit - credit)
        		else
          			new_balance = account.current_balance.to_d + (credit - debit)
        		end

        		account.update!(current_balance: new_balance)
      		end
    	end
    	return "Journal entry posted successfully."
  	end
end
