RSpec.describe "Admin finance contract periods", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  before do
    allow(Rails.application.config).to receive(:enable_finance_contract_periods).and_return(env_var_value)
  end

  describe "GET /admin/finance/contract-periods" do
    context "when enabled" do
      let(:env_var_value) { true }

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

  describe "GET /admin/finance/contract-periods/:id" do
    let(:contract_period) { FactoryBot.create(:contract_period) }

    context "when enabled" do
      let(:env_var_value) { true }

      it "redirects to sign in path when not signed in" do
        get "/admin/finance/contract-periods/#{contract_period.id}"
        expect(response).to redirect_to(sign_in_path)
      end

      context "with an authenticated non-DfE user" do
        include_context "sign in as non-DfE user"

        it "requires authorisation" do
          get "/admin/finance/contract-periods/#{contract_period.id}"
          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a non-finance DfE user" do
        include_context "sign in as DfE user"

        it "requires authorisation with the finance access error message" do
          get "/admin/finance/contract-periods/#{contract_period.id}"
          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a finance DfE user" do
        include_context "sign in as finance DfE user"

        it "displays the contract period show page" do
          get "/admin/finance/contract-periods/#{contract_period.id}"

          expect(response.status).to eq(200)
          expect(response.body).to include("Contract period #{contract_period.year}")
        end
      end
    end

    context "when disabled" do
      include_context "sign in as finance DfE user"

      context "implicitly" do
        let(:env_var_value) { nil }

        it "returns 404 not found" do
          get "/admin/finance/contract-periods/#{contract_period.id}"

          expect(response.status).to eq(404)
        end
      end

      context "explicitly" do
        let(:env_var_value) { false }

        it "returns 404 not found" do
          get "/admin/finance/contract-periods/#{contract_period.id}"

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "POST /admin/finance/contract-periods" do
    include_context "sign in as finance DfE user"

    context "when enabled" do
      let(:env_var_value) { true }

      context "with valid parameters" do
        let(:started_on) { 6.months.ago }
        let(:finished_on) { 3.months.ago }
        let(:valid_params) do
          {
            contract_period: {
              "year" => 2026,
              "started_on(3i)" => started_on.day,
              "started_on(2i)" => started_on.month,
              "started_on(1i)" => started_on.year,
              "finished_on(3i)" => finished_on.day,
              "finished_on(2i)" => finished_on.month,
              "finished_on(1i)" => finished_on.year,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "creates a new contract period" do
          expect { post admin_contract_periods_path, params: valid_params }.to change(ContractPeriod, :count).by(1)
        end

        it "redirects to the contract periods page with success message" do
          post admin_contract_periods_path, params: valid_params

          expect(response).to redirect_to(admin_contract_periods_path)
          expect(flash[:alert]).to eq("2026 Contract period added")
        end

        it "records a 'contract period created' event" do
          allow(Events::Record).to receive(:record_contract_period_added_event!).once.and_call_original

          post admin_contract_periods_path, params: valid_params

          expect(Events::Record).to have_received(:record_contract_period_added_event!)
          .once
          .with(
            hash_including(
              {
                author: kind_of(Sessions::User),
                contract_period: kind_of(ContractPeriod),
              }
            )
          )
        end

        it "creates the contract period with correct attributes" do
          post admin_contract_periods_path, params: valid_params

          contract_period = ContractPeriod.last
          expect(contract_period.year).to eq(2026)
          expect(contract_period.started_on).to eq(started_on.to_date)
          expect(contract_period.finished_on).to eq(finished_on.to_date)
          expect(contract_period.detailed_evidence_types_enabled).to be_truthy
          expect(contract_period.mentor_funding_enabled).to be_truthy
          expect(contract_period.uplift_fees_enabled).to be_falsey
        end
      end

      context "with invalid parameters" do
        let(:started_on) { nil }
        let(:finished_on) { 3.months.ago }
        let(:invalid_params) do
          {
            contract_period: {
              "year" => 2026,
              "started_on(3i)" => "",
              "started_on(2i)" => "",
              "started_on(1i)" => "",
              "finished_on(3i)" => finished_on.day,
              "finished_on(2i)" => finished_on.month,
              "finished_on(1i)" => finished_on.year,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "does not create a new contract period" do
          expect {
            post admin_contract_periods_path,
                 params: invalid_params
          }.not_to change(ContractPeriod, :count)
        end

        it "renders the new template with unprocessable_content status" do
          post admin_contract_periods_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Enter a start date")
        end

        it "shows validation errors" do
          post admin_contract_periods_path, params: invalid_params
          expect(response.body).to include("Enter a start date")
        end
      end

      context "with overlapping dates" do
        let!(:existing_period) do
          FactoryBot.create(:contract_period,
                            year: 2026,
                            started_on: 6.months.ago,
                            finished_on: 3.months.ago)
        end

        let(:overlapping_params) do
          {
            contract_period: {
              "year" => 2027,
              started_on: 4.months.ago,
              finished_on: 1.month.ago,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "does not create a new contract period" do
          expect {
            post admin_contract_periods_path, params: overlapping_params
          }.not_to change(ContractPeriod, :count)
        end

        it "renders the new template with unprocessable_content status" do
          post admin_contract_periods_path, params: overlapping_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Start date cannot overlap another Contract period")
        end

        it "shows validation errors" do
          post admin_contract_periods_path, params: overlapping_params
          expect(response.body).to include("Start date cannot overlap another Contract period")
        end
      end

      context "with end date before start date" do
        let(:started_on) { 6.months.ago }
        let(:finished_on) { started_on - 1.day }
        let(:params) do
          {
            contract_period: {
              "year" => 2026,
              "started_on(3i)" => started_on.day,
              "started_on(2i)" => started_on.month,
              "started_on(1i)" => started_on.year,
              "finished_on(3i)" => finished_on.day,
              "finished_on(2i)" => finished_on.month,
              "finished_on(1i)" => finished_on.year,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "does not create a new contract period" do
          expect {
            post admin_contract_periods_path, params:
          }.not_to change(ContractPeriod, :count)
        end

        it "returns unprocessable_content status" do
          post(admin_contract_periods_path, params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("The end date must be later than the start date")
        end

        it "shows appropriate error message" do
          post(admin_contract_periods_path, params:)
          expect(response.body).to include("The end date must be later than the start date")
        end
      end
    end

    context "when disabled" do
      let(:started_on) { 6.months.ago }
      let(:finished_on) { 3.months.ago }
      let(:params) do
        {
          contract_period: {
            "year" => 2026,
            "started_on(3i)" => started_on.day,
            "started_on(2i)" => started_on.month,
            "started_on(1i)" => started_on.year,
            "finished_on(3i)" => finished_on.day,
            "finished_on(2i)" => finished_on.month,
            "finished_on(1i)" => finished_on.year,
            detailed_evidence_types_enabled: true,
            mentor_funding_enabled: true,
            uplift_fees_enabled: false,
          }
        }
      end

      context "implicitly" do
        let(:env_var_value) { nil }

        it "returns 404 not found" do
          post(admin_contract_periods_path, params:)

          expect(response.status).to eq(404)
        end
      end

      context "explicitly" do
        let(:env_var_value) { false }

        it "returns 404 not found" do
          post(admin_contract_periods_path, params:)

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "GET /admin/finance/contract-periods/new" do
    include_context "sign in as finance DfE user"

    context "when enabled" do
      let(:env_var_value) { true }

      it "renders the new template" do
        get new_admin_contract_period_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Add Contract period")
      end

      it "shows the form" do
        get new_admin_contract_period_path
        expect(response.body).to include("Year")
        expect(response.body).to include("Start date")
        expect(response.body).to include("End date")
        expect(response.body).to include("Mentor funding enabled")
        expect(response.body).to include("Detailed evidence types enabled")
        expect(response.body).to include("Uplift fees enabled")
      end
    end

    context "when disabled" do
      context "implicitly" do
        let(:env_var_value) { nil }

        it "returns 404 not found" do
          get new_admin_contract_period_path

          expect(response.status).to eq(404)
        end
      end

      context "explicitly" do
        let(:env_var_value) { false }

        it "returns 404 not found" do
          get new_admin_contract_period_path

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "GET /admin/finance/contract-periods/:id/edit" do
    include_context "sign in as finance DfE user"

    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    context "when enabled" do
      let(:env_var_value) { true }

      it "returns success" do
        get edit_admin_contract_period_path(contract_period)
        expect(response).to be_successful
        expect(CGI.unescapeHTML(response.body)).to include("Edit #{contract_period.year} Contract period")
      end
    end

    context "when disabled" do
      context "implicitly" do
        let(:env_var_value) { nil }

        it "returns 404 not found" do
          get edit_admin_contract_period_path(contract_period)

          expect(response.status).to eq(404)
        end
      end

      context "explicitly" do
        let(:env_var_value) { false }

        it "returns 404 not found" do
          get edit_admin_contract_period_path(contract_period)

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "PATCH /admin/finance/contract-periods/:id" do
    include_context "sign in as finance DfE user"

    let!(:contract_period) { FactoryBot.create(:contract_period, year: Date.current.year + 2) }

    context "when enabled" do
      let(:env_var_value) { true }

      context "with valid parameters" do
        let(:valid_params) do
          {
            contract_period: {
              "year" => contract_period.year,
              started_on: Date.new(contract_period.started_on.year, 1, 1),
              finished_on: Date.new(contract_period.finished_on.year, 12, 31),
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "updates the contract period" do
          patch admin_contract_period_path(contract_period.id), params: valid_params

          expect(response).to redirect_to(admin_contract_periods_path)
          expect(flash[:alert]).to eq("#{contract_period.year} Contract period updated")

          contract_period.reload
          expect(contract_period.started_on).to eq(Date.new(contract_period.started_on.year, 1, 1))
          expect(contract_period.finished_on).to eq(Date.new(contract_period.finished_on.year, 12, 31))
          expect(contract_period.detailed_evidence_types_enabled).to be_truthy
          expect(contract_period.mentor_funding_enabled).to be_truthy
          expect(contract_period.uplift_fees_enabled).to be_falsey
        end

        it "records a contract period updated event" do
          allow(Events::Record).to receive(:record_contract_period_updated_event!).once.and_call_original

          contract_period.assign_attributes(valid_params[:contract_period])
          expected_modifications = contract_period.changes

          patch admin_contract_period_path(contract_period.id), params: valid_params

          expect(Events::Record).to have_received(:record_contract_period_updated_event!).once.with(
            hash_including(
              {
                contract_period:,
                author: kind_of(Sessions::User),
                modifications: hash_including(expected_modifications),
              }
            )
          )
        end
      end

      context "with invalid parameters" do
        let(:started_on) { nil }
        let(:finished_on) { 3.months.ago }
        let(:invalid_params) do
          {
            contract_period: {
              "year" => 2026,
              "started_on(3i)" => "",
              "started_on(2i)" => "",
              "started_on(1i)" => "",
              "finished_on(3i)" => finished_on.day,
              "finished_on(2i)" => finished_on.month,
              "finished_on(1i)" => finished_on.year,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "does not update the contract period" do
          expect {
            patch admin_contract_period_path(contract_period.id), params: invalid_params
          }.not_to(change { contract_period.reload.attributes })
        end

        it "renders the edit template with unprocessable_content status" do
          patch admin_contract_period_path(contract_period.id), params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Enter a start date")
        end

        it "shows validation errors" do
          patch admin_contract_period_path(contract_period.id), params: invalid_params
          expect(response.body).to include("Enter a start date")
        end
      end
    end
  end
end
