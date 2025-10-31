module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class Wizard < Mentors::Wizard
        steps do
          [{
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
          }]
        end

        def latest_registration_choice
          @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: mentor_trn)
        end

      private

        def mentor_trn
          mentor_at_school_period.teacher.trn
        end
      end
    end
  end
end
