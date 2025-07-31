module Metadata::Handler
  class School
    def create_metadata!(school)
      create_lead_provider_contract_period_metadata!(school)
    end

    def update_metadata!(school)
      school.lead_provider_contract_period_metadata.each do |metadata|
        update_lead_provider_contract_period_metadata!(metadata)
      end
    end

  private

    def create_lead_provider_contract_period_metadata!(school)
      lead_provider_and_contract_periods = school.school_partnerships.map do |partnership|
        [partnership.active_lead_provider.lead_provider, partnership.active_lead_provider.contract_period]
      end

      lead_provider_and_contract_periods.collect do |lead_provider, contract_period|
        next if school.lead_provider_contract_period_metadata.exists?(lead_provider:, contract_period:)
        next if Metadata::SchoolLeadProviderContractPeriod.where(school:, lead_provider:, contract_period:).exists?

        Metadata::SchoolLeadProviderContractPeriod.new(school:, lead_provider:, contract_period:).tap do |metadata|
          update_lead_provider_contract_period_metadata!(metadata)
        end
      end
    end

    def update_lead_provider_contract_period_metadata!(metadata)
      in_partnership = metadata.school.school_partnerships.for_contract_period(metadata.contract_period_id).exists?
      induction_programme_choice = metadata.school.training_programme_for(metadata.contract_period_id)
      expression_of_interest = [metadata.school.ect_at_school_periods, metadata.school.mentor_at_school_periods].any? do |scope|
        scope.with_expressions_of_interest_for_lead_provider_and_contract_period(
          metadata.contract_period_id,
          metadata.lead_provider_id
        ).exists?
      end

      metadata.assign_attributes(in_partnership:, expression_of_interest:, induction_programme_choice:)
      metadata.save! if metadata.changed?
    end
  end
end
