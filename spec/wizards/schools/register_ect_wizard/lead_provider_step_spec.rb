require_relative './shared_examples/lead_provider_step'

describe Schools::RegisterECTWizard::LeadProviderStep, type: :model do
  it_behaves_like 'a lead provider step'
end
