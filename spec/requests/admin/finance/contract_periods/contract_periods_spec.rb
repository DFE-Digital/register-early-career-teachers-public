RSpec.describe "Admin finance contract periods", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  before do
    allow(Rails.application.config).to receive(:enable_finance_contract_periods).and_return(env_var_value)
  end

  context "when enabled" do
    let(:env_var_value) { true }

    describe "GET /admin/finance/contract-periods" do
      it "redirects to sign in path when not signed in" do
        get "/admin/finance/contract-periods"
        expect(response).to redirect_to(sign_in_path)
      end

      context "with an authenticated non-DfE user" do
        include_context "sign in as non-DfE user"

        it "requires authorisation" do
          get "/admin/finance/contract-periods"
          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a non-finance DfE user" do
        include_context "sign in as DfE user"

        it "requires authorisation with the finance access error message" do
          get "/admin/finance/contract-periods"

          expect(response.status).to eq(401)

          expect(response.body).to include(
            "This is to access financial information for Register early career teachers. To gain access, contact the product team."
          )
        end
      end

      context "when signed in as a finance DfE user" do
        include_context "sign in as finance DfE user"

        it "displays the contract periods index page" do
          get "/admin/finance/contract-periods"

          expect(response.status).to eq(200)
        end
      end

      context "when disabled" do
        include_context "sign in as finance DfE user"

        context "implicitly" do
          let(:env_var_value) { nil }

          it "returns 404 not found" do
            get "/admin/finance/contract-periods"
            expect(response.status).to eq(404)
          end
        end

        context "explicitly" do
          let(:env_var_value) { false }

          it "returns 404 not found" do
            get "/admin/finance/contract-periods"
            expect(response.status).to eq(404)
          end
        end
      end
    end
  end
end
