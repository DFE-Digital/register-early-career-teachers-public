describe API::AddAPITokenToLeadProvider do
  subject { described_class.new(params) }

  let(:params) do
    {
      lead_provider_name_or_id:,
    }
  end

  before { allow(Rails.logger).to receive(:info).and_call_original }

  describe "#add" do
    context "with no params" do
      let(:lead_provider_name_or_id) { nil }

      before do
        FactoryBot.create_list(:lead_provider, 4)
      end

      it "creates new API Tokens for all Lead providers" do
        expect { subject.add }.to change(API::Token, :count).by(4)
      end
    end

    describe "using lead provider id in the params" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:api_tokens) { API::Token.where(lead_provider_id: lead_provider.id) }

      context "with known lead provider id" do
        let(:lead_provider_name_or_id) { lead_provider.id }

        it "creates a new API Token for the lead provider" do
          expect { subject.add }.to change(api_tokens, :count).by(1)
        end

        it "outputs the unhashed version of the new API Token" do
          subject.add

          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Started!/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Adding API Token for Lead provider #{lead_provider.name}/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: API Token \w+ successfully added to Lead provider #{lead_provider.name}\z/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Finished/)
        end
      end

      context "with unknown lead provider id" do
        let(:lead_provider_name_or_id) { 99 }

        it "errors and does not create token" do
          expect { subject.add }
            .to raise_exception(RuntimeError, "LeadProvider not found")
                  .and(not_change(API::Token, :count))
        end
      end
    end

    describe "using lead provider name in the params" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:api_tokens) { API::Token.where(lead_provider_id: lead_provider.id) }

      context "with known lead provider name" do
        let(:lead_provider_name_or_id) { lead_provider.name }

        it "creates a new API Token for the lead provider" do
          expect { subject.add }.to change(api_tokens, :count).by(1)
        end

        it "outputs the unhashed version of the new API Token" do
          subject.add

          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Started!/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Adding API Token for Lead provider #{lead_provider.name}/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: API Token \w+ successfully added to Lead provider #{lead_provider.name}\z/)
          expect(Rails.logger).to have_received(:info).with(/AddAPITokenToLeadProvider: Finished/)
        end
      end

      context "with unknown lead provider name" do
        let(:lead_provider_name_or_id) { "Any" }

        it "errors and does not create token" do
          expect { subject.add }
            .to raise_exception(RuntimeError, "LeadProvider not found")
                  .and(not_change(API::Token, :count))
        end
      end
    end
  end
end
