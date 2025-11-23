class ProductCategory < ApplicationRecord

  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: "parent_id", dependent: :nullify

  validates_presence_of :name
end
