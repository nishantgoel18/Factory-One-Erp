class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :non_deleted, -> {where(deleted: [nil, false])}

  def destroy!
    update_attribute(:deleted, true)
  end
end
