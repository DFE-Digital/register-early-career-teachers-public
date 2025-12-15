module Migration
  class LeadProvider < Migration::Base
    belongs_to :cpd_lead_provider
    has_many :partnerships
    has_and_belongs_to_many :cohorts
    belongs_to :cpd_lead_provider
  end
end
