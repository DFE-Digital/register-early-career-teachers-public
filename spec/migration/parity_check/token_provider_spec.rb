RSpec.describe ParityCheck::TokenProvider do
  before do
    FactoryBot.create_list(:lead_provider, 3)

    allow(Rails.application.config).to receive(:parity_check).and_return({
      enabled:,
      tokens: tokens.to_json
    })
  end

  let(:enabled) { true }
  let(:instance) { described_class.new }

  describe "#generate!" do
    subject(:generate) { instance.generate! }

    context "when the tokens are not present" do
      let(:tokens) { nil }

      it { expect { generate }.not_to change(API::Token, :count) }
    end

    context "when the tokens are present" do
      let(:tokens) do
        LeadProvider.all.each_with_object({}) do |lead_provider, hash|
          hash[lead_provider.ecf_id] = SecureRandom.uuid
        end
      end

      it { expect { generate }.to change(API::Token, :count).by(LeadProvider.count) }

      it "generates valid tokens for each lead provider" do
        generate

        LeadProvider.find_each do |lead_provider|
          token = tokens[lead_provider.ecf_id]
          expect(API::TokenManager.find_lead_provider_api_token(token:).lead_provider).to eq(lead_provider)
        end
      end

      context "when the tokens don't match the lead providers" do
        let(:tokens) { { "non_existent_ecf_id" => SecureRandom.uuid } }

        it { expect { generate }.not_to change(API::Token, :count) }
      end
    end

    context "when parity check is disabled" do
      let(:enabled) { false }
      let(:tokens) { nil }

      it { expect { generate }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end

  describe "#token" do
    subject(:token) { instance.token(lead_provider:) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    context "when the keys are not present" do
      let(:tokens) { nil }

      it { expect { token }.to raise_error(KeyError, /key not found: "#{lead_provider.ecf_id}"/) }
    end

    context "when the keys are present" do
      let(:tokens) { { lead_provider.ecf_id => "token" } }

      it { is_expected.to eq("token") }
    end

    context "when parity check is disabled" do
      let(:enabled) { false }
      let(:tokens) { nil }

      it { expect { token }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
