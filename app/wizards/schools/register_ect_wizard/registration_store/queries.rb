module Schools
  module RegisterECTWizard
    class RegistrationStore
      class Queries
        def initialize(registration_store:)
          @registration_store = registration_store
        end

        def ect_at_school_period
          @ect_at_school_period ||= ECTAtSchoolPeriod.find_by_id(registration_store.ect_at_school_period_id)
        end

        def active_record_at_school(urn)
          @active_record_at_school ||= ECTAtSchoolPeriods::Search.new.ect_periods(trn: registration_store.trn, urn:).ongoing.last
        end

        def appropriate_body
          @appropriate_body ||= AppropriateBody.find_by_id(registration_store.appropriate_body_id)
        end

        def lead_provider
          @lead_provider ||= LeadProvider.find(registration_store.lead_provider_id) if registration_store.lead_provider_id
        end

        def contract_start_date
          @contract_start_date ||= ContractPeriod.containing_date(registration_store.start_date&.to_date)
        end

        def lead_provider_partnership_for_contract_period(school:)
          contract_period = contract_start_date

          return SchoolPartnership.none unless previous_lead_provider && contract_period && school

          SchoolPartnerships::Search
            .new(school:, lead_provider: previous_lead_provider, contract_period:)
            .school_partnerships
        end

        def lead_providers_within_contract_period
          return [] unless contract_start_date

          @lead_providers_within_contract_period ||= LeadProviders::Active.in_contract_period(contract_start_date).select(:id, :name)
        end

        def previous_ect_at_school_period
          @previous_ect_at_school_period ||= ECTAtSchoolPeriods::Search
            .new(order: :started_on)
            .ect_periods(trn: registration_store.trn)
            .last
        end

        def previous_school
          previous_ect_at_school_period&.school
        end

        def ordered_induction_periods
          @ordered_induction_periods ||= InductionPeriods::Search
            .new(order: :started_on)
            .induction_periods(trn: registration_store.trn)
        end

        def first_induction_period
          ordered_induction_periods.first
        end

        def previous_induction_period
          ordered_induction_periods.last
        end

        def previous_training_period
          return unless previous_ect_at_school_period

          @previous_training_period ||= TrainingPeriods::Search
            .new(order: :started_on)
            .training_periods(ect_id: previous_ect_at_school_period.id)
            .last
        end

        def previous_appropriate_body
          previous_induction_period&.appropriate_body
        end

        def previous_delivery_partner
          previous_training_period&.delivery_partner
        end

        def previous_lead_provider
          previous_training_period&.lead_provider
        end

      private

        attr_reader :registration_store
      end
    end
  end
end
