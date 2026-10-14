module Schools::AssignExistingMentorWizard::Steps
  class ReviewMentorEligibilityStep
    include DfE::Wizard::Step

    def self.permitted_params = []

    def lead_provider = wizard.ect_lead_provider
  end
end
