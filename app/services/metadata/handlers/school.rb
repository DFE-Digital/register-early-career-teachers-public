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

    class << self
      def destroy_all_metadata!
        truncate_models!(Metadata::SchoolContractPeriod, Metadata::SchoolLeadProviderContractPeriod)
      end
    end

  private

    def upsert_contract_period_metadata!
      changes_to_upsert = contract_period_years.each_with_object({}) do |contract_period_year, hash|
        metadata = existing_contract_period_metadata[contract_period_year] ||
          Metadata::SchoolContractPeriod.new(school:, contract_period_year:)

        changes = {
          school_id: school.id,
          contract_period_year:,
          in_partnership: contract_period_year.in?(school_partnership_contract_period_years),
          induction_programme_choice: school.training_programme_for(contract_period_year)
        }

        hash[metadata] = changes if changes?(metadata, changes)
      end

      upsert_all(model: Metadata::SchoolContractPeriod, changes_to_upsert:, unique_by: %i[school_id contract_period_year])
    end

    def upsert_lead_provider_contract_period_metadata!
      changes_to_upsert = lead_provider_id_contract_period_years.each_with_object({}) do |(lead_provider_id, contract_period_year), hash|
        metadata = existing_lead_provider_contract_period_metadata[[lead_provider_id, contract_period_year]] ||
          Metadata::SchoolLeadProviderContractPeriod.new(school:, lead_provider_id:, contract_period_year:)

        changes = {
          school_id: school.id,
          lead_provider_id:,
          contract_period_year:,
          expression_of_interest: expressions_of_interest.include?([lead_provider_id, contract_period_year])
        }

        upsert(metadata, expression_of_interest:)
      end

      upsert_all(model: Metadata::SchoolLeadProviderContractPeriod, changes_to_upsert:, unique_by: %i[school_id lead_provider_id contract_period_year])
    end

    def expressions_of_interest
      @expressions_of_interest ||= school.lead_providers_and_contract_periods_with_expression_of_interest_or_school_partnership
    end

    def lead_provider_id_contract_period_years
      @lead_provider_id_contract_period_years ||= lead_provider_ids.product(contract_period_years)
    end

    def contract_period_years
      @contract_period_years ||= ContractPeriod.pluck(:year)
    end

    def school_partnership_contract_period_years
      @school_partnership_contract_period_years ||= school.school_partnerships
        .includes(lead_provider_delivery_partnership: :active_lead_provider)
        .pluck(:contract_period_year)
        .uniq
    end

    def existing_contract_period_metadata
      @existing_contract_period_metadata ||= Metadata::SchoolContractPeriod
        .where(school:, contract_period_year: contract_period_years)
        .index_by(&:contract_period_year)
    end

    def existing_lead_provider_contract_period_metadata
      @existing_lead_provider_contract_period_metadata ||= Metadata::SchoolLeadProviderContractPeriod
        .where(school:, lead_provider_id: lead_provider_ids, contract_period_year: contract_period_years)
        .index_by { |m| [m.lead_provider_id, m.contract_period_year] }
    end
  end
end
