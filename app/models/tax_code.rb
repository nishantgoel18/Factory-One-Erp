class TaxCode < ApplicationRecord
  include OrganizationScoped
  # -------------------------------
  # ENUM-LIKE CONSTANTS
  # -------------------------------
  JURISDICTIONS = {
    "FEDERAL"  => "Federal",
    "STATE"    => "State",
    "PROVINCE" => "Province",
    "COUNTY"   => "County",
    "CITY"     => "City",
    "SPECIAL"  => "Special District"
  }.freeze

  TAX_TYPES = {
    "SALES" => "Sales Tax",
    "USE"   => "Use Tax",
    "VAT"   => "VAT",
    "GST"   => "GST",
    "HST"   => "HST",
    "PST"   => "PST"
  }.freeze

  FILING_FREQUENCIES = {
    "MONTHLY"   => "Monthly",
    "QUARTERLY" => "Quarterly",
    "ANNUALLY"  => "Annually"
  }.freeze

  # -------------------------------
  # VALIDATIONS
  # -------------------------------
  validates :code, uniqueness: true, allow_blank: true
  validates :name, presence: true
  validates :jurisdiction, presence: true, inclusion: { in: JURISDICTIONS.keys }
  validates :tax_type, presence: true, inclusion: { in: TAX_TYPES.keys }

  validates :rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  validate :jurisdiction_hierarchy_validation
  validate :effective_date_validation
  validate :compound_tax_validation

  scope :active, -> { where(is_active: true, deleted: false) }
  scope :not_deleted, -> { where(deleted: false) }

  # -------------------------------
  # CUSTOM VALIDATION METHODS
  # -------------------------------
  def jurisdiction_hierarchy_validation
    if jurisdiction == "FEDERAL" && (state_province.present? || county.present? || city.present?)
      errors.add(:base, "Federal taxes cannot have state/county/city specified")
    end

    if jurisdiction == "STATE" && state_province.blank?
      errors.add(:state_province, "State level taxes must specify state/province")
    end

    if jurisdiction == "COUNTY" && county.blank?
      errors.add(:county, "County taxes require county")
    end
  end

  def effective_date_validation
    if effective_to.present? && effective_to < effective_from
      errors.add(:effective_to, "cannot be earlier than effective from")
    end
  end

  def compound_tax_validation
    if is_compound? && compounds_on.blank?
      errors.add(:base, "Compound taxes must specify which tax they compound on")
    end
  end

  # -------------------------------
  # AUTO-GENERATE CODE
  # -------------------------------
  before_save :generate_code_if_blank

  def generate_code_if_blank
    return if code.present?

    base_code = tax_type.dup
    base_code += "-#{state_province}" if state_province.present?
    base_code += "-#{county}" if county.present?
    base_code += "-#{city}" if city.present?

    # Ensure uniqueness
    proposed = base_code
    counter = 1

    while TaxCode.where(code: proposed).where.not(id: id).exists?
      proposed = "#{base_code}-#{counter}"
      counter += 1
    end

    self.code = proposed
  end

  # -------------------------------
  # DISPLAY METHOD
  # -------------------------------
  def display_name
    "#{code} - #{name} (#{(rate.to_f * 100).round(2)}%)"
  end
end
