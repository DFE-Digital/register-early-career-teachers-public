module Migration
  class Statement < Migration::Base
    self.inheritance_column = nil

    belongs_to :cohort
    belongs_to :cpd_lead_provider
    has_one :lead_provider, through: :cpd_lead_provider

    default_scope { where("statements.type ilike ?", "Finance::Statement::ECF%") }
  end
end
