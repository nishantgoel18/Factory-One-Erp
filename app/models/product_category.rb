class ProductCategory < ApplicationRecord

  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: "parent_id", dependent: :nullify

  validates_presence_of :name

  validate :cannot_be_its_own_parent

  def cannot_be_its_own_parent
    if parent_id.present? && self.parent == self
      errors.add(:parent_id, "cannot be the same as the category itself")
    end
  end
end
