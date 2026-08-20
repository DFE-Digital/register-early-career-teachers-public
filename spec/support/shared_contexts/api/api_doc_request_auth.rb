RSpec.shared_context("with authorization for api doc request") do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:lead_provider) { framework_agreement.lead_provider }
  let(:token) { generate_api_token.token }
  let(:Authorization) { "Bearer #{token}" }
end
