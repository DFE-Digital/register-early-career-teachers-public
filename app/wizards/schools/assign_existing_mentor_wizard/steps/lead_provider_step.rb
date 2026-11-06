module Schools::AssignExistingMentorWizard::Steps
  class LeadProviderStep
    include DfE::Wizard::Step

    def self.permitted_params = %i[lead_provider_id]

    attribute :lead_provider_id, :integer

    validates :lead_provider_id,
              presence: { message: "Select a lead provider to contact your school" },
              lead_provider: { message: "Select a lead provider to contact your school" }

    def lead_provider = LeadProvider.find(lead_provider_id)
  end
end
