class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :non_deleted, -> {where.not(deleted: true)}

  def destroy!
    update_attribute(:deleted, true)
  end
end
