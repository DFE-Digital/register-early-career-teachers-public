RSpec.describe ParityCheck::TokenProvider do
  before do
    FactoryBot.create_list(:lead_provider, 3)

    allow(Rails.application.config).to receive(:parity_check).and_return({
      enabled:,
      tokens: tokens.to_json
    })
  end

  let(:instance) { described_class.new }

  describe "#generate!" do
    subject(:generate) { instance.generate! }

    context "when parity check is enabled" do
      let(:enabled) { true }

      context "when the tokens are not present" do
        let(:tokens) { nil }

        it { expect { generate }.not_to change(API::Token, :count) }
      end

      context "when the tokens are present" do
        let(:tokens) do
          LeadProvider.all.each_with_object({}) do |lead_provider, hash|
            hash[lead_provider.api_id] = SecureRandom.uuid
          end
        end

        it { expect { generate }.to change(API::Token, :count).by(LeadProvider.count) }

        it "generates valid tokens for each lead provider" do
          generate

          LeadProvider.find_each do |lead_provider|
            token = tokens[lead_provider.api_id]
            expect(API::TokenManager.find_lead_provider_api_token(token:).lead_provider).to eq(lead_provider)
          end
        end

        context "when the tokens don't match the lead providers" do
          let(:tokens) { { "non_existent_api_id" => SecureRandom.uuid } }

          it { expect { generate }.not_to change(API::Token, :count) }
        end
      end
    end

    context "when parity check is disabled" do
      let(:enabled) { false }
      let(:tokens) { nil }

      it { expect { generate }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
