RSpec.describe "Admin finance schedules", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:index_path) { admin_contract_period_schedules_path(contract_period) }

  context "when disabled" do
    include_context "sign in as finance DfE user"

    it "returns 404 not found" do
      get index_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/finance/contract-periods/:contract_period_id/schedules", :enable_finance_contract_periods do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get index_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get index_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        get index_path
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
        get index_path
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

  describe "GET /admin/finance/contract-periods/:contract_period_id/schedules/new", :enable_finance_contract_periods do
    let(:new_path) { new_admin_contract_period_schedule_path(contract_period) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        get new_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get new_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        get new_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("To gain access, contact the product team.")
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the new schedule page" do
        get new_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Standard January")
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "redirects to the schedules page" do
          get new_path
          expect(response).to redirect_to(admin_contract_period_schedules_path(contract_period))
        end
      end
    end
  end

  describe "GET /admin/finance/contract-periods/:contract_period_id/schedules/:id", :enable_finance_contract_periods do
    let(:schedule) { FactoryBot.create(:schedule, contract_period:) }
    let(:show_path) { admin_contract_period_schedule_path(contract_period, schedule) }

    it "redirects to sign in path when not signed in" do
      get show_path
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get show_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        get show_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("To gain access, contact the product team.")
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "displays the schedule show page" do
        get show_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(schedule.name)
      end
    end
  end

  describe "POST /admin/finance/contract-periods/:contract_period_id/schedules/:id", :enable_finance_contract_periods do
    let(:params) do
      { schedule: { identifier: "ecf-standard-january" } }
    end

    context "when not authenticated" do
      it "redirects to sign in page" do
        post(index_path, params:)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        post(index_path, params:)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates a schedule and redirects to the index" do
        expect { post(index_path, params:) }.to change(Schedule, :count).by(1)

        expect(response).to redirect_to(admin_contract_period_schedules_path(contract_period))
        expect(flash[:alert]).to eq("Standard January schedule added")
      end

      context "when the identifier is invalid" do
        let(:params) { { schedule: { identifier: "invalid-identifier" } } }

        it "does not create a schedule and re-renders new" do
          expect { post(index_path, params:) }.not_to(change(Schedule, :count))
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Choose an identifier from the list")
        end
      end

      context "when the schedule parameters are missing" do
        let(:params) { {} }

        it "does not create a schedule and re-renders new" do
          expect { post(index_path, params:) }.not_to(change(Schedule, :count))
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Select a schedule")
        end
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "does not create a schedule and redirects with an error" do
          expect { post(index_path, params:) }.not_to(change(Schedule, :count))

          expect(response).to redirect_to(admin_contract_period_schedules_path(contract_period))
          expect(flash[:error]).to eq("Schedules cannot be edited once the contract period has started")
        end
      end
    end
  end

  describe "DELETE /admin/finance/contract-periods/:contract_period_id/schedules/:id", :enable_finance_contract_periods do
    let!(:schedule) { FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january") }
    let(:destroy_path) { admin_contract_period_schedule_path(contract_period, schedule) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        delete destroy_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        delete destroy_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        delete destroy_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("To gain access, contact the product team.")
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "destroys the schedule and redirects to the index" do
        expect { delete destroy_path }.to change(Schedule, :count).by(-1)

        expect(response).to redirect_to(admin_contract_period_schedules_path(contract_period))
        expect(flash[:alert]).to eq("Standard January schedule removed")
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "does not destroy the schedule and redirects with an error" do
          expect { delete destroy_path }.not_to(change(Schedule, :count))
          expect(response).to redirect_to(admin_contract_period_schedules_path(contract_period))
          expect(flash[:error]).to eq("Schedules cannot be edited once the contract period has started")
        end
      end
    end
  end
end
