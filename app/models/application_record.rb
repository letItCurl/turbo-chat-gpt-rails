class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  default_scope { order('created_at ASC') }
end
