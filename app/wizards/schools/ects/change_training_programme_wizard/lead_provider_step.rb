module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class LeadProviderStep < Step
        attribute :lead_provider_id, :string

        validates :lead_provider_id,
                  presence: { message: "Select which lead provider will be training the ECT" },
                  lead_provider: { message: "Enter the name of a known lead provider" }

        def self.permitted_params = [:lead_provider_id]

        def previous_step = :edit
        def next_step = :check_answers

        def lead_providers_for_select
          return [] unless contract_period

          LeadProvider
            .where(id: ActiveLeadProvider.where(contract_period_year: contract_period.year).select(:lead_provider_id))
            .select(:id, :name)
            .order(:name)
        end

        def save!
          store.lead_provider_id = lead_provider_id if valid_step?
        end

      private

        def pre_populate_attributes
          self.lead_provider_id = store.lead_provider_id
        end

        def contract_period
          @contract_period ||= contract_period_reassignment.required? ? successor_contract_period : contract_period_on_start_date
        end

        def contract_period_on_start_date
          ContractPeriod.containing_date(ect_at_school_period.started_on)
        end

        def contract_period_reassignment
          @contract_period_reassignment ||= ContractPeriods::Reassignment.new(training_period: last_provider_led_training_period)
        end

        delegate :successor_contract_period, to: :contract_period_reassignment

        def last_provider_led_training_period
          @last_provider_led_training_period ||= ect_at_school_period.training_periods.provider_led_training_programme.latest_first.first
        end
      end
    end
  end
end
