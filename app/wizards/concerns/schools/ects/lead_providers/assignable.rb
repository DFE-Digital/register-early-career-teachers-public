module Schools
  module ECTs
    module LeadProviders
      module Assignable
        extend ActiveSupport::Concern

        def lead_providers_for_select = active_lead_providers_in_contract_period
        def current_lead_provider = lead_provider_for_ect_at_school_period
        def current_lead_provider_name = current_lead_provider&.name

      private

        def selected_lead_provider
          @selected_lead_provider ||= if store.accepting_current_lead_provider
                                        lead_provider_for_ect_at_school_period
                                      else
                                        LeadProvider.find(store.lead_provider_id)
                                      end
        end

        def ect_at_school_period_training
          ECTAtSchoolPeriods::CurrentTraining.new(ect_at_school_period)
        end

        def lead_provider_for_ect_at_school_period
          @lead_provider_for_ect_at_school_period ||= ect_at_school_period_training
            .lead_provider_via_school_partnership_or_eoi
        end

        def active_lead_providers_in_contract_period
          return [] unless contract_period

          @active_lead_providers_in_contract_period ||= ::LeadProviders::Active
            .in_contract_period(contract_period)
            .select(:id, :name)
        end

        def contract_period
          @contract_period ||= ContractPeriod.containing_date(ect_at_school_period.started_on)
        end
      end
    end
  end
end
