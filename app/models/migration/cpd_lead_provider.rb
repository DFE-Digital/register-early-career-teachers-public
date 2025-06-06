module Migration
  class CpdLeadProvider < Migration::Base
    has_one :lead_provider
    has_many :statements
  end
end
