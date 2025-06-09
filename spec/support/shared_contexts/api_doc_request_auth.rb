RSpec.shared_context("with authorization for api doc request") do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }
  let(:token) { generate_api_token.token }
  let(:Authorization) { "Bearer #{token}" } # rubocop:disable RSpec/VariableName
end
