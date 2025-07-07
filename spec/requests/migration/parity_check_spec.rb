RSpec.describe "Parity check", type: :request do
  let(:enabled) { true }

  before { allow(Rails.configuration).to receive(:parity_check).and_return({ enabled: }) }

  describe "GET /migration/parity_checks/new" do
    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "renders the parity checks page" do
        get new_migration_parity_check_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Run a parity check")
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          get new_migration_parity_check_path
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        get new_migration_parity_check_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end

  describe "POST /migration/parity_checks" do
    let!(:lead_provider) { create(:lead_provider) }
    let!(:endpoints) { create_list(:parity_check_endpoint, 2) }
    let(:endpoint_ids) { endpoints.map(&:id) }
    let(:mode) { "sequential" }

    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "calls the runner and redirects if valid" do
        params = { parity_check_runner: { endpoint_ids:, mode: } }
        expect { post migration_parity_checks_path, params: }.to change(ParityCheck::Run, :count).by(1)
        expect(response).to redirect_to(new_migration_parity_check_path)

        created_run = ParityCheck::Run.last
        expect(created_run.requests.pluck(:endpoint_id)).to match_array(endpoint_ids)
        expect(created_run.mode).to eq(mode)
      end

      it "does not call the runner and renders an error if invalid" do
        params = { parity_check_runner: { endpoint_ids: [] } }
        expect { post migration_parity_checks_path, params: }.not_to change(ParityCheck::Run, :count)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Select at least one endpoint.")
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          post migration_parity_checks_path, params: { parity_check_runner: { endpoint_ids: } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        post migration_parity_checks_path, params: { parity_check_runner: { endpoint_ids: } }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end

  describe "GET /migration/parity_checks/completed" do
    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "renders the completed parity checks page" do
        get completed_migration_parity_checks_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Completed parity checks")
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          get completed_migration_parity_checks_path
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        get completed_migration_parity_checks_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end

  describe "GET /migration/parity_checks/:id" do
    let(:run) { create(:parity_check_run, :completed) }

    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "renders the parity check run page" do
        get migration_parity_check_path(run)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Parity check run ##{run.id}")
      end

      context "when the parity check is not completed" do
        let(:run) { create(:parity_check_run, :in_progress) }

        it "renders 404 not found" do
          get migration_parity_check_path(run)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the parity check does not exist" do
        it "renders 404 not found" do
          get migration_parity_check_path(99)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          get migration_parity_check_path(run)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        get migration_parity_check_path(run)
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end

  describe "GET /migration/parity_checks/:run_id/requests/:id" do
    let(:run) { create(:parity_check_run, :completed) }
    let(:request) { create(:parity_check_request, :completed, run:) }

    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "renders the parity check request page" do
        get migration_parity_check_request_path(run, request)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(request.description)
      end

      context "when the parity check is not completed" do
        let(:run) { create(:parity_check_run, :in_progress) }

        it "renders 404 not found" do
          get migration_parity_check_request_path(run, request)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the request does not exist" do
        it "renders 404 not found" do
          get migration_parity_check_request_path(run, 99)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the run does not exist" do
        it "renders 404 not found" do
          get migration_parity_check_request_path(99, request)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          get migration_parity_check_request_path(run, request)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        get migration_parity_check_request_path(run, request)
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end

  describe "GET /migration/parity_checks/:run_id/responses/:id" do
    let(:run) { create(:parity_check_run, :completed) }
    let(:request) { create(:parity_check_request, :completed, run:) }
    let(:parity_check_response) { create(:parity_check_response, :different, request:) }

    context "when signed in as a DfE user" do
      include_context 'sign in as DfE user'

      it "renders the parity check response page" do
        get migration_parity_check_response_path(run, parity_check_response)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(parity_check_response.description)
      end

      context "when the parity check is not completed" do
        let(:run) { create(:parity_check_run, :in_progress) }

        it "renders 404 not found" do
          get migration_parity_check_response_path(run, request)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the response does not exist" do
        it "renders 404 not found" do
          get migration_parity_check_response_path(run, 99)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the response is matching" do
        let(:parity_check_response) { create(:parity_check_response, :matching, request:) }

        it "renders 404 not found" do
          get migration_parity_check_response_path(run, 99)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the run does not exist" do
        it "renders 404 not found" do
          get migration_parity_check_response_path(99, request)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when parity check is disabled" do
        let(:enabled) { false }

        it "renders 404 not found" do
          get migration_parity_check_response_path(run, request)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when not signed in as a DfE user" do
      include_context 'sign in as non-DfE user'

      it "renders the unauthorized page" do
        get migration_parity_check_response_path(run, request)
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("You are not authorised to access this page")
      end
    end
  end
end
