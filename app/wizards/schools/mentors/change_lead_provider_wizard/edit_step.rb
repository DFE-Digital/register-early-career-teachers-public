module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class EditStep < Mentors::Step
        attribute :lead_provider_id, :string

        validates :lead_provider_id,
                  presence: { message: "Select a lead provider to contact your school" }

        def self.permitted_params = %i[lead_provider_id]

        def next_step = :check_answers

        def save!
          store.update!(lead_provider_id:) if valid_step?
        end

        def lead_providers_for_select
          active_lead_providers_in_contract_period
            .without(lead_provider_for_mentor_at_school_period)
        end

      private

        def pre_populate_attributes
          self.lead_provider_id = store.lead_provider_id.presence
        end

        def active_lead_providers_in_contract_period
          return [] unless contract_period

          @active_lead_providers_in_contract_period ||= ::LeadProviders::Active
            .in_contract_period(contract_period)
            .select(:id, :name)
        end

        def contract_period
          @contract_period ||= ContractPeriod.containing_date(mentor_at_school_period.started_on)
        end

        def lead_provider_for_mentor_at_school_period
          wizard.latest_registration_choice.lead_provider
        end
      end
    end
  end
end
