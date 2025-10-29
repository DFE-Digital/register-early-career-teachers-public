module Schools
  module ECTs
    module ChangeMentorWizard
      class Wizard < ECTs::Wizard
        steps do
          [{
            edit: EditStep,
            review_mentor_eligibility: ReviewMentorEligibilityStep,
            lead_provider: LeadProviderStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep
          }]
        end
      end
    end
  end
end
