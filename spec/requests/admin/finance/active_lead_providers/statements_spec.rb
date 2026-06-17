RSpec.describe "Admin finance active lead provider statements", :enable_finance_contract_periods, type: :request do
  include ActiveJob::TestHelper

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }

  let(:index_path) { admin_contract_period_active_lead_provider_statements_path(contract_period, active_lead_provider) }
  let(:new_path) { new_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider) }
  let(:statement_path) { admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }
  let(:edit_path) { edit_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }
  let(:delete_path) { delete_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }

  describe "GET .../statements" do
    let!(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    it "redirects to sign in path when not signed in" do
      get index_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get index_path
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the active lead provider's statements" do
        get index_path

        expect(response.status).to eq(200)
        expect(response.body).to include("Lead Provider 1")
        expect(response.body).to include(Statements::Period.for(statement))
        expect(response.body).to include(admin_contract_period_active_lead_providers_path(contract_period))
      end
    end
  end

  describe "GET .../statements/new" do
    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the new form" do
        get new_path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started but is not frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "allows the new form" do
          get new_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the contract period is frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current, :with_payments_frozen) }

        it "blocks the new form, redirecting to the index" do
          get new_path
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get new_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST .../statements" do
    let!(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:) }

    let(:params) do
      {
        contract_id: contract.id,
        month: 11,
        year: contract_period.year,
        deadline_date: Date.new(contract_period.year, 11, 1),
        payment_date: Date.new(contract_period.year, 12, 25)
      }
    end

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates a statement and redirects to it" do
        expect {
          perform_enqueued_jobs { post index_path, params: { statement: params } }
        }.to change(Statement, :count).by(1)

        statement = Statement.last
        expect(response).to redirect_to(admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement))
        expect(statement.contract).to eq(contract)
        expect(statement).to be_status_open
      end

      context "when the params are invalid" do
        let(:params) { super().merge(month: "99") }

        it "re-renders with an error status" do
          post index_path, params: { statement: params }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract belongs to another active lead provider" do
        let(:other_contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }
        let(:params) { super().merge(contract_id: other_contract.id) }

        it "does not create a statement" do
          expect {
            post index_path, params: { statement: params }
          }.not_to change(Statement, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract period has started but is not frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "allows the create" do
          expect {
            perform_enqueued_jobs { post index_path, params: { statement: params } }
          }.to change(Statement, :count).by(1)
        end
      end

      context "when the contract period is frozen" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current, :with_payments_frozen) }

        it "blocks the create, redirecting to the index" do
          expect {
            post index_path, params: { statement: params }
          }.not_to change(Statement, :count)
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        post index_path, params: { statement: params }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET .../statements/:id" do
    let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the statement" do
        get statement_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get statement_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET .../statements/:id/edit" do
    let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the edit form" do
        get edit_path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the edit form, redirecting to the index" do
          get edit_path
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get edit_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH .../statements/:id" do
    let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "updates the statement and redirects to it" do
        perform_enqueued_jobs do
          patch statement_path, params: { statement: { payment_date: Date.new(contract_period.year, 12, 26) } }
        end

        expect(response).to redirect_to(statement_path)
        expect(statement.reload.payment_date).to eq(Date.new(contract_period.year, 12, 26))
      end

      context "when the params are invalid" do
        it "re-renders with an error status" do
          patch statement_path, params: { statement: { month: "99" } }

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the contract belongs to another active lead provider" do
        let(:other_contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

        it "does not change the statement's contract" do
          original_contract = statement.contract

          patch statement_path, params: { statement: { contract_id: other_contract.id } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(statement.reload.contract).to eq(original_contract)
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the update, redirecting to the index" do
          original_payment_date = statement.payment_date

          patch statement_path, params: { statement: { payment_date: Date.new(contract_period.year, 12, 26) } }

          expect(response).to redirect_to(index_path)
          expect(statement.reload.payment_date).to eq(original_payment_date)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        patch statement_path, params: { statement: { payment_date: Date.new(contract_period.year, 12, 26) } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET .../statements/:id/delete" do
    let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "renders the delete confirmation" do
        get delete_path
        expect(response).to have_http_status(:ok)
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the delete confirmation, redirecting to the index" do
          get delete_path
          expect(response).to redirect_to(index_path)
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        get delete_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE .../statements/:id" do
    let!(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: contract_period.year) }

    context "when signed in as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the statement and redirects to the index" do
        expect {
          perform_enqueued_jobs { delete statement_path }
        }.to change(Statement, :count).by(-1)
        expect(response).to redirect_to(index_path)
      end

      context "when the statement has declarations" do
        let!(:declaration) { FactoryBot.create(:declaration, :eligible, active_lead_provider:, payment_statement: statement) }

        it "does not destroy it and redirects to the statement with an error" do
          expect {
            delete statement_path
          }.not_to change(Statement, :count)

          expect(response).to redirect_to(statement_path)
          expect(flash[:error]).to eq("Cannot delete a statement with declarations")
        end
      end

      context "when the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :current) }

        it "blocks the destroy, redirecting to the index" do
          expect {
            delete statement_path
          }.not_to change(Statement, :count)
          expect(response).to redirect_to(index_path)
          expect(flash[:error]).to eq("Statements cannot be changed once the contract period has started")
        end
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation" do
        delete statement_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
