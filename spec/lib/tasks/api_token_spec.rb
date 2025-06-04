RSpec.describe "API Token tasks" do
  before { allow(Rails.logger).to receive(:info).and_call_original }

  describe "api_token:lead_provider:generate_token" do
    subject :run_task do
      Rake::Task["api_token:lead_provider:generate_token"].invoke(lead_provider_name_or_id)
    end

    after do
      Rake::Task["api_token:lead_provider:generate_token"].reenable
    end

    context "with no params" do
      let(:lead_provider_name_or_id) { nil }

      it "errors and does not create token" do
        expect { run_task }
          .to raise_exception(RuntimeError, "LeadProvider not found")
                .and(not_change(API::Token, :count))
      end
    end

    describe "using lead provider id in the params" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:api_tokens) { API::Token.where(lead_provider_id: lead_provider.id) }

      context "with known lead provider id" do
        let(:lead_provider_name_or_id) { lead_provider.id }

        it "creates a new API Token for the lead provider" do
          expect { run_task }.to change(api_tokens, :count).by(1)
        end

        it "outputs the unhashed version of the new API Token" do
          run_task

          expect(Rails.logger).to have_received(:info).with(/\AAPI Token created: \w+ for Lead provider: #{lead_provider.name}\z/)
        end
      end

      context "with unknown lead provider id" do
        let(:lead_provider_name_or_id) { 99 }

        it "errors and does not create token" do
          expect { run_task }
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
          expect { run_task }.to change(api_tokens, :count).by(1)
        end

        it "outputs the unhashed version of the new API Token" do
          run_task

          expect(Rails.logger).to have_received(:info).with(/\AAPI Token created: \w+ for Lead provider: #{lead_provider.name}\z/)
        end
      end

      context "with unknown lead provider name" do
        let(:lead_provider_name_or_id) { "Any" }

        it "errors and does not create token" do
          expect { run_task }
            .to raise_exception(RuntimeError, "LeadProvider not found")
                  .and(not_change(API::Token, :count))
        end
      end
    end
  end
end
