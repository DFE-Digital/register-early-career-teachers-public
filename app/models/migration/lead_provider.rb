module Migration
  class LeadProvider < Migration::Base
    has_many :partnerships
    has_and_belongs_to_many :cohorts
  end
end
