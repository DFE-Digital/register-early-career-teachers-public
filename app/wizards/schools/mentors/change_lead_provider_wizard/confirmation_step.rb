module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_lead_provider
          latest_registration_choice.lead_provider
        end
        
        private
          def latest_registration_choice
            @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: mentor_trn)
          end
      end
    end
  end
end
