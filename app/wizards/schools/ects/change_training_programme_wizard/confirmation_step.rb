module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_training_programme = store.training_programme

        def provider_name
          return unless training_period && lead_provider

          lead_provider&.name
        end

      private

        def lead_provider
          training_period.lead_provider.presence ||
            training_period.expression_of_interest&.lead_provider
        end

        def training_period = ect_at_school_period.current_or_next_training_period
      end
    end
  end
end
