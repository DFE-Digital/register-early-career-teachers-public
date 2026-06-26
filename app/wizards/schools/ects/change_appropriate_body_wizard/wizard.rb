module Schools
  module ECTs
    module ChangeAppropriateBodyWizard
      class Wizard < ECTs::Wizard
        attr_accessor :ect_at_school_period

        delegate :school, to: :ect_at_school_period

        steps do
          [
            {
              independent_school: IndependentSchoolStep,
              state_school: StateSchoolStep,
              check_answers: CheckAnswersStep,
              confirmation: ConfirmationStep
            }
          ]
        end

        def allowed_steps
          [
            first_step,
            :check_answers,
            :confirmation
          ]
        end

        private

        def first_step
          school.independent? ? :independent_school : :state_school
        end
      end
    end
  end
end
