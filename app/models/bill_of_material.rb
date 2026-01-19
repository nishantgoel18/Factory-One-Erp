class BillOfMaterial < ApplicationRecord
    include OrganizationScoped
    belongs_to :product
    # belongs_to :created_by, class_name: "User", optional: true

    has_many :bom_items, -> { where(deleted: false) }, dependent: :destroy

    accepts_nested_attributes_for :bom_items, allow_destroy: true

    STATUS_CHOICES = %w[DRAFT ACTIVE INACTIVE ARCHIVED]

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :revision, length: { maximum: 16 }
    validates :status, inclusion: { in: STATUS_CHOICES }
    validates :effective_from, presence: true

    validates :product_id, uniqueness: { scope: :revision, message: "must be unique for this product" }

    validate :product_must_allow_bom
    validate :date_range_must_be_valid
    validate :only_one_default_per_product
    validate :default_bom_must_be_active
    validate :no_overlapping_active_ranges
    validate :active_bom_must_have_items
    validate :archived_cannot_be_default

    before_save :handle_active_status
    before_save :ensure_single_default

    after_save :recompute_product_cost

    def can_be_activated?
        self.status != 'ACTIVE'
    end

    def product_must_allow_bom
        allowed_types = ["Finished Goods", "Semi-Finished Goods"]

        unless allowed_types.include?(self.product.product_type)
            errors.add(:product_id, "can only have a BOM if it is a Finished or Semi-Finished product")
        end
    end

    def date_range_must_be_valid
        if self.effective_to.present? && self.effective_to < self.effective_from
            errors.add(:base, "Effective To date cannot be earlier than Effective From date.")
        end
    end

    def only_one_default_per_product
        return unless self.is_default?

        conflict = BillOfMaterial.non_deleted.where(product_id: self.product_id, is_default: true).where.not(id: self.id)
        if conflict.exists?
            errors.add(:is_default, "Only one default BOM is allowed per product.")
        end
    end

    def default_bom_must_be_active
        if self.is_default? && self.status != "ACTIVE"
            errors.add(:is_default, "Only an 'Active' BOM can be set as default.")
        end
    end

    def active_bom_must_have_items
        return unless self.status == "ACTIVE"

        # only one ACTIVE bom allowed
        if BillOfMaterial.non_deleted.where(product_id: self.product_id, status: "ACTIVE").where.not(id: self.id).exists?
            errors.add(:status, "Only one ACTIVE BOM per product")
        end

        if bom_items.empty?
            errors.add(:base, "An Active BOM must contain at least one component line.")
        end
    end

    def archived_cannot_be_default
        if status == "ARCHIVED" && self.is_default?
            errors.add(:is_default, "ARCHIVED BOM cannot be marked as default.")
        end
    end

    def no_overlapping_active_ranges
        return unless status == "ACTIVE"

        from = effective_from
        to   = effective_to || effective_from

        overlap_exists = BillOfMaterial.non_deleted
            .where(product_id: product_id, status: "ACTIVE")
            .where.not(id: id)
            .where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", to, from)
            .exists?

        if overlap_exists
            errors.add(:base, "Another ACTIVE BOM exists for this product within the same effective date range.")
        end
    end

    def handle_active_status
        return unless status == "ACTIVE"

        # Archive other active BOMs
        BillOfMaterial.non_deleted.where(product_id: product_id, status: "ACTIVE").where.not(id: id).update_all(status: "ARCHIVED", is_default: false)

        # Auto-set default if not already
        self.is_default = true unless is_default?
    end

    def ensure_single_default
        return unless self.is_default?

        BillOfMaterial.non_deleted.where(product_id: self.product_id)
           .where.not(id: self.id)
           .update_all(is_default: false)
    end

    def recompute_product_cost
        return unless self.is_default? && self.status == "ACTIVE"
        
        total_cost = BigDecimal("0")

        self.bom_items.where(deleted: false).includes(:component).each do |item|
            component_cost = item.component.standard_cost.to_d || BigDecimal("0")
            qty = item.quantity.to_d

            total_cost += qty * component_cost
        end

        self.product.update_column(:standard_cost, total_cost)
    end
end
