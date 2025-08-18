module Metadata::Handlers
  class School < Base
    attr_reader :school

    def initialize(school)
      @school = school
    end

    def refresh_metadata!
      upsert_contract_period_metadata!
      upsert_lead_provider_contract_period_metadata!
    end

  private

    def upsert_contract_period_metadata!
      contract_period_years.each do |contract_period_year|
        metadata = Metadata::SchoolContractPeriod.find_or_initialize_by(
          school:,
          contract_period_year:
        )

        in_partnership = school.school_partnerships.for_contract_period(contract_period_year).exists?
        induction_programme_choice = school.training_programme_for(contract_period_year)

        upsert(metadata, in_partnership:, induction_programme_choice:)
      end
    end

    def upsert_lead_provider_contract_period_metadata!
      lead_provider_id_contract_period_years.each do |lead_provider_id, contract_period_year|
        metadata = Metadata::SchoolLeadProviderContractPeriod.find_or_initialize_by(
          school:,
          lead_provider_id:,
          contract_period_year:
        )

        expression_of_interest = school.expression_of_interest_for?(lead_provider_id, contract_period_year)

        upsert(metadata, expression_of_interest:)
      end
    end

    def lead_provider_id_contract_period_years
      @lead_provider_id_contract_period_years ||= lead_provider_ids.product(contract_period_years)
    end

    def contract_period_years
      @contract_period_years ||= ContractPeriod.pluck(:year)
    end
  end
end
