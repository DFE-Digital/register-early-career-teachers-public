RSpec.describe "Admin finance contract periods", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  describe "GET /admin/finance/contract-periods" do
    context "when disabled" do
      include_context "sign in as finance DfE user"

      it "returns 404 not found" do
        get "/admin/finance/contract-periods"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when enabled", :enable_finance_contract_periods do
      it "redirects to sign in path when not signed in" do
        get "/admin/finance/contract-periods"
        expect(response).to redirect_to(sign_in_path)
      end

      context "with an authenticated non-DfE user" do
        include_context "sign in as non-DfE user"

        it "requires authorisation" do
          get "/admin/finance/contract-periods"
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when signed in as a non-finance DfE user" do
        include_context "sign in as DfE user"

        it "requires authorisation with the finance access error message" do
          get "/admin/finance/contract-periods"
          expect(response).to have_http_status(:unauthorized)
          expect(response.body).to include(
            "This is to access financial information for Register early career teachers. To gain access, contact the product team."
          )
        end
      end

      context "when signed in as a finance DfE user" do
        include_context "sign in as finance DfE user"

        it "displays the contract periods index page" do
          get "/admin/finance/contract-periods"
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe "GET /admin/finance/contract-periods/:id" do
    context "when disabled" do
      include_context "sign in as finance DfE user"

      it "returns 404 not found" do
        get "/admin/finance/contract-periods/#{contract_period.id}"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when enabled", :enable_finance_contract_periods do
      it "redirects to sign in path when not signed in" do
        get "/admin/finance/contract-periods/#{contract_period.id}"
        expect(response).to redirect_to(sign_in_path)
      end

      context "with an authenticated non-DfE user" do
        include_context "sign in as non-DfE user"

        it "requires authorisation" do
          get "/admin/finance/contract-periods/#{contract_period.id}"
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when signed in as a non-finance DfE user" do
        include_context "sign in as DfE user"

        it "requires authorisation with the finance access error message" do
          get "/admin/finance/contract-periods/#{contract_period.id}"
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when signed in as a finance DfE user" do
        include_context "sign in as finance DfE user"

        it "displays the contract period show page" do
          get "/admin/finance/contract-periods/#{contract_period.id}"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("#{contract_period.year} contract period")
        end
      end
    end
  end

  describe "POST /admin/finance/contract-periods" do
    include_context "sign in as finance DfE user"

    context "when disabled" do
      let(:params) do
        {
          contract_period: {
            "year" => 2026,
            detailed_evidence_types_enabled: true,
            mentor_funding_enabled: true,
            uplift_fees_enabled: false,
          }
        }
      end

      it "returns 404 not found" do
        post(admin_contract_periods_path, params:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when enabled", :enable_finance_contract_periods do
      context "with valid parameters" do
        # An existing contract period is required by the service
        # which creates schedules and milestones based on the most recent contract period
        let!(:existing_period) do
          FactoryBot.create(:contract_period,
                            year: 2025,
                            started_on: 1.year.ago,
                            finished_on: Date.current)
        end

        let(:started_on) { 1.month.from_now }
        let(:finished_on) { 12.months.from_now }
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

        it "creates a new contract period" do
          expect { post(admin_contract_periods_path, params:) }.to change(ContractPeriod, :count).by(1)
        end

        it "redirects to the contract periods page with success message" do
          post(admin_contract_periods_path, params:)
          expect(response).to redirect_to(admin_contract_periods_path)
          expect(flash[:alert]).to eq("2026 Contract period added")
        end

        it "records a 'contract period created' event" do
          allow(Events::Record).to receive(:record_contract_period_added_event!).once.and_call_original

          post(admin_contract_periods_path, params:)

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
          post(admin_contract_periods_path, params:)

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
        let(:finished_on) { 3.months.from_now }
        let(:params) do
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
          expect { post(admin_contract_periods_path, params:) }.not_to change(ContractPeriod, :count)
        end

        it "renders the new template with unprocessable_content status" do
          post(admin_contract_periods_path, params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Enter a start date")
        end

        it "shows validation errors" do
          post(admin_contract_periods_path, params:)
          expect(response.body).to include("Enter a start date")
        end
      end

      context "with overlapping dates" do
        let!(:existing_period) do
          FactoryBot.create(:contract_period,
                            year: 2026,
                            started_on: 6.months.ago,
                            finished_on: 3.months.from_now)
        end

        let(:started_on) { 4.months.ago }
        let(:finished_on) { 1.month.from_now }

        let(:params) do
          {
            contract_period: {
              "year" => 2027,
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
          expect { post(admin_contract_periods_path, params:) }.not_to change(ContractPeriod, :count)
        end

        it "renders the new template with unprocessable_content status" do
          post(admin_contract_periods_path, params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Start date cannot overlap another Contract period")
        end

        it "shows validation errors" do
          post(admin_contract_periods_path, params:)
          expect(response.body).to include("Start date cannot overlap another Contract period")
        end
      end

      context "with end date before start date" do
        let(:started_on) { 6.months.from_now }
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
          expect { post(admin_contract_periods_path, params:) }.not_to change(ContractPeriod, :count)
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

    context "when seeding from previous", :enable_finance_contract_periods do
      context "with invalid params" do
        let(:params) do
          {
            contract_period: {
              "year" => 2027,
              "started_on(3i)" => "1",
              "started_on(2i)" => "10",
              "started_on(1i)" => "2007",
              "finished_on(3i)" => "1",
              "finished_on(2i)" => "10",
              "finished_on(1i)" => "2008",
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "does not create a new contract period" do
          expect { post(admin_contract_periods_path, params:) }.not_to change(ContractPeriod, :count)
        end

        it "renders the new template with unprocessable_content status" do
          post(admin_contract_periods_path, params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Cannot seed contract period")
        end
      end
    end
  end

  describe "GET /admin/finance/contract-periods/new" do
    include_context "sign in as finance DfE user"

    context "when disabled" do
      it "returns 404 not found" do
        get new_admin_contract_period_path
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when enabled", :enable_finance_contract_periods do
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
  end

  describe "GET /admin/finance/contract-periods/:id/edit" do
    include_context "sign in as finance DfE user"

    let(:contract_period) { FactoryBot.create(:contract_period, :next) }

    context "when disabled" do
      it "returns 404 not found" do
        get edit_admin_contract_period_path(contract_period)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when enabled", :enable_finance_contract_periods do
      it "returns success" do
        get edit_admin_contract_period_path(contract_period)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Edit #{contract_period.year} Contract period")
      end
    end
  end

  describe "PATCH /admin/finance/contract-periods/:id" do
    include_context "sign in as finance DfE user"

    let!(:contract_period) do
      FactoryBot.create(:contract_period, year: Date.current.next_year(2).year)
    end

    context "when enabled", :enable_finance_contract_periods do
      context "with valid parameters" do
        let(:params) do
          {
            contract_period: {
              "year" => contract_period.year,
              "started_on(3i)" => "1",
              "started_on(2i)" => "1",
              "started_on(1i)" => contract_period.started_on.year.to_s,
              "finished_on(3i)" => "31",
              "finished_on(2i)" => "12",
              "finished_on(1i)" => contract_period.finished_on.year.to_s,
              detailed_evidence_types_enabled: true,
              mentor_funding_enabled: true,
              uplift_fees_enabled: false,
            }
          }
        end

        it "updates the contract period" do
          patch(admin_contract_period_path(contract_period.id), params:)

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

          contract_period.assign_attributes(params[:contract_period])
          expected_modifications = contract_period.changes

          patch(admin_contract_period_path(contract_period.id), params:)

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
        let(:finished_on) { 3.months.from_now }
        let(:params) do
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
            patch(admin_contract_period_path(contract_period.id), params:)
          }.not_to(change { contract_period.reload.attributes })
        end

        it "renders the edit template with unprocessable_content status" do
          patch(admin_contract_period_path(contract_period.id), params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Enter a start date")
        end

        it "shows validation errors" do
          patch(admin_contract_period_path(contract_period.id), params:)
          expect(response.body).to include("Enter a start date")
        end
      end
    end
  end
end
