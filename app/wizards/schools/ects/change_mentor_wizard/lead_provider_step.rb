module Schools
  module ECTs
    module ChangeMentorWizard
      class LeadProviderStep < Step
        attribute :lead_provider_id, :string

        validates :lead_provider_id,
                  presence: { message: "Select which lead provider will be training the ECT" },
                  lead_provider: { message: "Enter the name of a known lead provider" }

        def self.permitted_params = [:lead_provider_id]

        def previous_step = :training
        def next_step = :check_answers

        def new_mentor_name = name_for(selected_mentor_at_school_period.teacher)

        def save!
          store.lead_provider_id = lead_provider_id if valid_step?
        end

        def lead_providers_for_select
          active_lead_providers_in_contract_period
            .without(lead_provider_for_ect_at_school_period)
        end

      private

        def pre_populate_attributes
          self.lead_provider_id = store.lead_provider_id
        end

        def selected_mentor_at_school_period
          ect_at_school_period
            .school
            .mentor_at_school_periods
            .find(store.mentor_at_school_period_id)
        end

        def active_lead_providers_in_contract_period
          return [] unless contract_period

          @active_lead_providers_in_contract_period ||= ::LeadProviders::Active
            .in_contract_period(contract_period)
            .select(:id, :name)
        end

        def contract_period
          @contract_period ||= ContractPeriod
            .containing_date(selected_mentor_at_school_period.started_on)
        end

        def lead_provider_for_ect_at_school_period
          @lead_provider_for_ect_at_school_period ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end
      end
    end
  end
end
