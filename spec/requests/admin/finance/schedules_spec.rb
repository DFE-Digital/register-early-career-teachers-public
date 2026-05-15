RSpec.describe "Admin finance schedules", :enable_finance_contract_periods do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  describe "GET /admin/finance/contract-periods/:id/schedules" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get "/admin/finance/contract-periods/#{contract_period.id}/schedules"
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/finance/contract-periods/#{contract_period.id}/schedules"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        get "/admin/finance/contract-periods/#{contract_period.id}/schedules"
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("To gain access, contact the product team.")
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      before do
        FactoryBot.create(:schedule, identifier: "ecf-standard-january", contract_period:)
        FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period:)
        FactoryBot.create(:schedule, identifier: "ecf-extended-january")
        get "/admin/finance/contract-periods/#{contract_period.id}/schedules"
      end

      context "and the contract period is closed" do
        let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }

        it "displays the schedules index page" do
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Manage schedules for the 2025 contract period.")
        end

        it "displays the schedules for the contract period" do
          expect(response.body).to include("Standard January")
          expect(response.body).to include("Standard April")
          expect(response.body).not_to include("Extended January")
        end

        it "has a disabled button" do
          expect(response.body).to include("Add schedule")
          expect(response.body).to include('data-module="govuk-button" disabled="disabled"')
        end
      end

      context "and the contract period is not yet open" do
        let(:contract_period) { FactoryBot.create(:contract_period, :next) }

        it "has an enabled button" do
          expect(response.body).to include("Add schedule")
          expect(response.body).not_to include('data-module="govuk-button" disabled="disabled"')
        end
      end
    end
  end
end
