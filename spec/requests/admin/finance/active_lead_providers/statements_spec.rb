RSpec.describe "Admin finance active lead provider statements", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }

  let!(:output_statement) do
    FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year)
  end

  let!(:service_statement) do
    FactoryBot.create(:statement, :paid, :service_fee, active_lead_provider:, month: 1, year: contract_period.year.next)
  end

  let(:path) { admin_active_lead_provider_statements_path(active_lead_provider) }

  before do
    allow(Rails.application.config).to receive(:enable_finance_contract_periods).and_return(env_var_value)
  end

  describe "GET /admin/finance/active-lead-providers/:active_lead_provider_id/statements" do
    context "when enabled" do
      let(:env_var_value) { true }

      it "redirects to sign in path when not signed in" do
        get path
        expect(response).to redirect_to(sign_in_path)
      end

      context "with an authenticated non-DfE user" do
        include_context "sign in as non-DfE user"

        it "requires authorisation" do
          get path
          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a non-finance DfE user" do
        include_context "sign in as DfE user"

        it "requires authorisation" do
          get path
          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a finance DfE user" do
        include_context "sign in as finance DfE user"

        it "displays the statements in a single table for the active lead provider" do
          get path

          expect(response.status).to eq(200)
          expect(response.body).to include("Lead Provider 1")
          expect(response.body).to include("Month")
          expect(response.body).to include("Fee type")
          expect(response.body).to include("Status")
          expect(response.body).to include("Deadline date")
          expect(response.body).to include("Payment date")
        end

        it "includes both output and service fee statements" do
          get path

          expect(response.body).to include(Statements::Period.for(output_statement))
          expect(response.body).to include(Statements::Period.for(service_statement))
          expect(response.body).to include("Output")
          expect(response.body).to include("Service")
        end

        it "shows the status as a tag" do
          get path

          expect(response.body).to include("Open")
          expect(response.body).to include("Paid")
        end

        describe "the Add statement button" do
          context "when the contract period has started" do
            let(:contract_period) { FactoryBot.create(:contract_period, :current) }

            it "renders the button in a disabled state" do
              get path

              expect(response.body).to include("Add statement")
              expect(response.body).to include('aria-disabled="true"')
            end
          end

          context "when the contract period has not started" do
            let(:contract_period) { FactoryBot.create(:contract_period, :next) }

            it "renders the button enabled" do
              get path

              expect(response.body).to include("Add statement")
              expect(response.body).not_to include('aria-disabled="true"')
            end
          end
        end

        context "when there are no statements" do
          let(:other_lead_provider) { FactoryBot.create(:lead_provider, name: "No statements LP") }
          let(:other_active_lead_provider) do
            FactoryBot.create(:active_lead_provider, contract_period:, lead_provider: other_lead_provider)
          end
          let(:path) { admin_active_lead_provider_statements_path(other_active_lead_provider) }

          it "shows an empty message" do
            get path

            expect(response.status).to eq(200)
            expect(response.body).to include("No statements found")
          end
        end
      end
    end

    context "when disabled" do
      include_context "sign in as finance DfE user"

      context "implicitly" do
        let(:env_var_value) { nil }

        it "returns 404 not found" do
          get path
          expect(response.status).to eq(404)
        end
      end

      context "explicitly" do
        let(:env_var_value) { false }

        it "returns 404 not found" do
          get path
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
