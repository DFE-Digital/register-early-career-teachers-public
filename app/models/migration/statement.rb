module Migration
  class Statement < Migration::Base
    self.inheritance_column = nil

    belongs_to :cohort
    belongs_to :cpd_lead_provider
    has_one :lead_provider, through: :cpd_lead_provider

    default_scope { where("statements.type ilike ?", "Finance::Statement::ECF%") }

    def sanitized_mentor_contract_version
      # ECF has a DB default of 0.0.1, even for statements that
      # are not in a mentor funding cohort!
      cohort.mentor_funding? ? mentor_contract_version : nil
    end

    def contract
      CallOffContract.find_by!(
        version: contract_version,
        cohort:,
        lead_provider:
      )
    end

    def mentor_contract
      MentorCallOffContract.find_by!(
        version: mentor_contract_version,
        cohort:,
        lead_provider:
      )
    end
  end
end
