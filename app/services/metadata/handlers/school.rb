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
      existing_metadata = Metadata::SchoolContractPeriod
              .where(school:, contract_period_year: contract_period_years)
              .index_by(&:contract_period_year)

      changes_to_upsert = []

      contract_period_years.each do |contract_period_year|
        metadata = existing_metadata[contract_period_year] ||
          Metadata::SchoolContractPeriod.new(school:, contract_period_year:)

        changes = {
          school_id: school.id,
          contract_period_year:,
          in_partnership: school.school_partnerships.for_contract_period(contract_period_year).exists?,
          induction_programme_choice: school.training_programme_for(contract_period_year)
        }

        next if metadata.attributes.slice(*changes.keys) == changes

        alert_on_changes(metadata:, changes:)
        changes_to_upsert << changes
      end

      Metadata::SchoolContractPeriod.upsert_all(changes_to_upsert, unique_by: %i[school_id contract_period_year])
    end

    def upsert_lead_provider_contract_period_metadata!
      existing_metadata = Metadata::SchoolLeadProviderContractPeriod
              .where(school:, lead_provider_id: lead_provider_ids, contract_period_year: contract_period_years)
              .index_by { |m| [m.lead_provider_id, m.contract_period_year] }

      changes_to_upsert = []

      lead_provider_id_contract_period_years.each do |lead_provider_id, contract_period_year|
        metadata = existing_metadata[[lead_provider_id, contract_period_year]] ||
          Metadata::SchoolLeadProviderContractPeriod.new(school:, lead_provider_id:, contract_period_year:)

        changes = {
          school_id: school.id,
          lead_provider_id:,
          contract_period_year:,
          expression_of_interest: school.expression_of_interest_for?(lead_provider_id, contract_period_year)
        }

        next if metadata.attributes.slice(*changes.keys) == changes

        alert_on_changes(metadata:, changes:)
        changes_to_upsert << changes
      end

      Metadata::SchoolLeadProviderContractPeriod.upsert_all(changes_to_upsert, unique_by: %i[school_id lead_provider_id contract_period_year])
    end

    def lead_provider_id_contract_period_years
      @lead_provider_id_contract_period_years ||= lead_provider_ids.product(contract_period_years)
    end

    def contract_period_years
      @contract_period_years ||= ContractPeriod.pluck(:year)
    end
  end
end
