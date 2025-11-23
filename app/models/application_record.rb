class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :non_deleted, -> {where(deleted: false)}
end
