module Schools
  module ECTs
    module ChangeMentorWizard
      class Wizard < ECTs::Wizard
        steps do
          [{
            edit: EditStep,
            training: TrainingStep,
            lead_provider: LeadProviderStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end

        def name_for(...) = Teachers::Name.new(...).full_name
      end
    end
  end
end
