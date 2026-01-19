class BomItem < ApplicationRecord
    include OrganizationScoped
    belongs_to :bom
    belongs_to :component, class_name: "Product"
    belongs_to :uom, class_name: "UnitOfMeasure"

    validates :quantity, numericality: { greater_than: 0 }
    validates :scrap_percent, numericality: { 
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 100 
    }

    validates :scrap_percent, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 100}

    validates :component_id, uniqueness: { scope: :bom_id, message: "already exists in this BOM" }

    validate :allowed_component_types
    validate  :no_decimal_if_uom_disallows
    validate  :component_cannot_equal_parent_product

    def allowed_component_types
        allowed_types = ['Raw Material', 'Service', 'Consumable']

        unless allowed_types.include?(self.component.product_type)
            errors.add(:product_id, "can only have a BOM Item if it is a #{allowed_types.to_sentence} component")
        end
    end

    def no_decimal_if_uom_disallows
        return if quantity.blank?
        return if uom&.is_decimal?

        # If UOM does not allow decimals
        if quantity.to_d != quantity.to_i
            errors.add(:quantity, "Decimal quantity not allowed for this UoM")
        end
    end
    
    def component_cannot_equal_parent_product
        if component_id.present? && bom&.product_id == component_id
            errors.add(:component, "cannot be the same as the parent product")
        end
    end
end
