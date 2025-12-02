class StockTransfer < ApplicationRecord
  STATUS_DRAFT     = "DRAFT"
  STATUS_POSTED    = "POSTED"
  STATUS_CANCELLED = "CANCELLED"

  STATUSES = [STATUS_DRAFT, STATUS_POSTED, STATUS_CANCELLED].freeze

  belongs_to :from_warehouse, class_name: "Warehouse"
  belongs_to :to_warehouse, class_name: "Warehouse"
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :posted_by, class_name: "User", optional: true

  has_many :lines,
           class_name: "StockTransferLine",
           dependent: :destroy,
           inverse_of: :stock_transfer

  accepts_nested_attributes_for :lines, allow_destroy: true

  validates :transfer_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :different_warehouses

  scope :active, -> { where(deleted: false) }
  scope :draft, -> { where(status: STATUS_DRAFT, deleted: false) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED, deleted: false) }
  scope :posted, -> { where(status: STATUS_POSTED, deleted: false) }

  before_validation :generate_transfer_no
  def different_warehouses
    if from_warehouse_id.present? && to_warehouse_id.present? &&
       from_warehouse_id == to_warehouse_id
      errors.add(:base, "From and To warehouse cannot be the same")
    end
  end

  def can_edit?
    status == STATUS_DRAFT
  end

  def posted?
    status == STATUS_POSTED
  end
  
  def can_post?
    status == STATUS_DRAFT && lines.where(deleted: false).exists?
  end

  def post!(user:)
    raise "Cannot post this transfer" unless can_post?

    StockTransfer.transaction do
      lines.where(deleted: false).find_each do |line|
        # OUT
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: "TRANSFER_OUT",
          quantity: line.qty,
          from_location: line.from_location,
          to_location: nil,
          batch: line.batch_if_applicable,
          reference_type: "STOCK_TRANSFER",
          reference_id: id.to_s,
          note: line.line_note,
          created_by: user
        )

        # IN
        StockTransaction.create!(
          product: line.product,
          uom: line.uom,
          txn_type: "TRANSFER_IN",
          quantity: line.qty,
          from_location: nil,
          to_location: line.to_location,
          batch: line.batch_if_applicable,
          reference_type: "STOCK_TRANSFER",
          reference_id: id.to_s,
          note: line.line_note,
          created_by: user
        )
      end

      update!(
        status: STATUS_POSTED,
        approved_by: approved_by || user,
        posted_at: DateTime.now
      )
    end
  end

  private

  def generate_transfer_no
    self.transfer_number ||= "STR-#{Time.now.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end
end
