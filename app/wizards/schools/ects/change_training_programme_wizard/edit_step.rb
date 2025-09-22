module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class EditStep < Step
        attribute :training_programme, :string

        validates :training_programme, training_programme: true

        def self.permitted_params = [:training_programme]

        def next_step
          if training_programme == "provider_led"
            :lead_provider
          else
            :check_answers
          end
        end

        def save!
          store.training_programme = training_programme if valid_step?
        end

      private

        delegate :valid_step?, to: :wizard

        def pre_populate_attributes
          self.training_programme = store.training_programme
        end
      end
    end
  end
end
