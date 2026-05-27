RSpec.shared_context("with authorization for api doc request") do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:lead_provider) { active_lead_provider.lead_provider }
  let(:token) { generate_api_token.token }
  let(:Authorization) { "Bearer #{token}" }
end
