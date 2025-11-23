class UnitOfMeasure < ApplicationRecord

  validates_uniqueness_of :name, :symbol
  validates :name, presence: true, length: { maximum: 100 }
  validates :symbol, presence: true, length: { maximum: 10 } 

end
