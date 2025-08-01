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
      LeadProvider.all.to_a.product(ContractPeriod.all.to_a).collect do |lead_provider, contract_period|
        next if school.lead_provider_contract_period_metadata.exists?(school:, lead_provider:, contract_period:)

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
