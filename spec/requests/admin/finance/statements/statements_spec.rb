RSpec.describe "Admin finance statements index", type: :request do
  describe "GET /admin/finance/statements" do
    it "redirects to sign in path" do
      get "/admin/finance/statements"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/finance/statements"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with the finance access error message" do
        get "/admin/finance/statements"

        expect(response.status).to eq(401)

        expect(response.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the finance page" do
        get "/admin/finance/statements"

        expect(response.status).to eq(200)
      end

      it "retrieves a list of statements" do
        allow(Statements::Search).to receive(:new).and_call_original

        get "/admin/finance/statements"

        expect(Statements::Search).to have_received(:new).once
      end
    end
  end

  describe "GET /admin/finance/statements/:statement_id" do
    it "redirects to sign in path" do
      get "/admin/finance/statements/1"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/finance/statements/1"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"
      let!(:statement) { FactoryBot.create(:statement) }

      it "requires authorisation with the finance access error message" do
        get "/admin/finance/statements/#{statement.id}"

        expect(response.status).to eq(401)

        expect(response.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end

    context "when signed in as a DfE finance user" do
      include_context "sign in as finance DfE user"
      let!(:statement) { FactoryBot.create(:statement) }

      it "displays the finance page" do
        get "/admin/finance/statements/#{statement.id}"

        expect(response.status).to eq(200)
      end

      it "uses the presenter to display the statement" do
        allow(Admin::StatementPresenter).to receive(:new).with(statement).and_call_original

        get "/admin/finance/statements/#{statement.id}"

        expect(Admin::StatementPresenter).to have_received(:new).with(statement).once
      end
    end
  end

  describe "GET /admin/finance/statements/:statement_id/declarations_export.csv" do
    let!(:statement) { FactoryBot.create(:statement) }

    it "redirects to sign in path" do
      get "/admin/finance/statements/#{statement.id}/declarations_export.csv"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/finance/statements/#{statement.id}/declarations_export.csv"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with the finance access error message" do
        get "/admin/finance/statements/#{statement.id}/declarations_export.csv"

        expect(response.status).to eq(401)
        expect(response.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end

    context "when signed in as a DfE finance user" do
      include_context "sign in as finance DfE user"

      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
      let(:banded_fee_structure) do
        FactoryBot.create(:contract_banded_fee_structure).tap do |structure|
          FactoryBot.create(
            :contract_banded_fee_structure_band,
            banded_fee_structure: structure,
            min_declarations: 1,
            max_declarations: 100
          )
        end
      end
      let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:, banded_fee_structure:) }
      let!(:statement) do
        FactoryBot.create(
          :statement,
          :paid,
          contract:,
          active_lead_provider:,
          month: 11,
          year: 2024
        )
      end
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:school_partnership) do
        FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership: FactoryBot.create(
            :lead_provider_delivery_partnership,
            active_lead_provider:,
            delivery_partner:
          )
        )
      end
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :ongoing,
          school_partnership:,
          started_on: Date.new(2024, 10, 1)
        )
      end
      let!(:declaration) do
        FactoryBot.create(
          :declaration,
          :paid,
          training_period:,
          payment_statement: statement
        )
      end
      let!(:unrelated_declaration) { FactoryBot.create(:declaration, :paid) }

      it "downloads the statement declarations as CSV" do
        get "/admin/finance/statements/#{statement.id}/declarations_export.csv"

        expect(response.status).to eq(200)
        expect(response.media_type).to eq("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.body).to include(declaration.api_id)
        expect(response.body).not_to include(unrelated_declaration.api_id)
      end

      context "when the statement is for service fees" do
        let!(:statement) do
          FactoryBot.create(
            :statement,
            :paid,
            :service_fee,
            contract:,
            active_lead_provider:,
            month: 11,
            year: 2024
          )
        end

        it "returns not found" do
          get "/admin/finance/statements/#{statement.id}/declarations_export.csv"

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
