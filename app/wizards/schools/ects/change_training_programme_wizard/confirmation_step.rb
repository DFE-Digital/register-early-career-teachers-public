module Schools
  module ECTs
    module ChangeTrainingProgrammeWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_training_programme = store.training_programme
      end
    end
  end
end
