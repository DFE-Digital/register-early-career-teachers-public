module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class EditStep < Mentors::Step
        # TODO shouldn't this be an integer
        attribute :lead_provider_id, :string

        validates :lead_provider_id,
                  presence: { message: "Select a lead provider" }
                  

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
        # TODO - query is this a check on whether to prepopulate? Or just setting the value?
        def pre_populate_attributes
          self.lead_provider_id = store.lead_provider_id.presence || wizard.lead_provider_id
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
          latest_registration_choice.lead_provider
        end

        def latest_registration_choice
          @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: mentor_trn)
        end

        def mentor_trn
          mentor_at_school_period.teacher.trn
        end

      end
    end
  end
end
