RSpec.describe "Admin finance milestones", type: :request do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }

  context "when disabled" do
    include_context "sign in as finance DfE user"

    it "returns 404 not found" do
      get "/admin/finance/contract-periods/#{contract_period.id}/schedules/#{schedule.id}/milestones/new"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/finance/contract-periods/:contract_period_id/schedules/:schedule_id/milestones/new", :enable_finance_contract_periods do
    let(:new_path) { new_admin_contract_period_schedule_milestone_path(contract_period, schedule) }

    context "when not authenticated" do
      it "redirects to sign in page" do
        get new_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
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

      it "displays the new milestone page" do
        get new_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Add milestone")
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "redirects to the schedule page" do
          get new_path
          expect(response).to redirect_to(admin_contract_period_schedule_path(contract_period, schedule))
        end
      end
    end
  end

  describe "POST /admin/finance/contract-periods/:contract_period_id/schedules/:schedule_id/milestones/:id", :enable_finance_contract_periods do
    let(:index_path) { admin_contract_period_schedule_milestones_path(contract_period, schedule) }

    let(:start_date) { Time.zone.now }
    let(:params) do
      {
        contract_period_id: contract_period.id,
        schedule_id: schedule.id,
        milestone: {
          declaration_type: "started",
          "start_date(3i)" => start_date.day,
          "start_date(2i)" => start_date.month,
          "start_date(1i)" => start_date.year,
          milestone_date: "",
        }
      }
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

    context "when authenticated as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "requires authorisation with finance privileges" do
        post(index_path, params:)
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("To gain access, contact the product team.")
      end
    end

    context "when authenticated as a finance DfE user" do
      include_context "sign in as finance DfE user"

      it "creates a new milesone" do
        expect { post(index_path, params:) }.to change(Milestone, :count).by(1)
      end

      it "redirects to the schedule page" do
        post(index_path, params:)
        expect(response).to redirect_to(admin_contract_period_schedule_path(contract_period, schedule))
        expect(flash[:alert]).to eq("Started milestone added")
      end

      it "records an event" do
        allow(Events::Record).to receive(:record_milestone_added_event!).once.and_call_original
        post(index_path, params:)
        expect(Events::Record).to have_received(:record_milestone_added_event!).once
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "does not create a milestone and redirects with an error" do
          expect { post(index_path, params:) }.not_to(change(Milestone, :count))

          expect(response).to redirect_to(admin_contract_period_schedule_path(contract_period, schedule))
          expect(flash[:error]).to eq("Milestones cannot be edited once the contract period has started")
        end
      end
    end
  end

  describe "DELETE /admin/finance/contract-periods/:contract_period_id/schedules/:schedule_id/milestones/:id", :enable_finance_contract_periods do
    let!(:milestone) { FactoryBot.create(:milestone, schedule:) }
    let(:destroy_path) { admin_contract_period_schedule_milestone_path(contract_period, schedule, milestone) }

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

      it "destroys the milestone and redirects to the schedule page" do
        expect { delete destroy_path }.to change(Milestone, :count).by(-1)

        expect(response).to redirect_to(admin_contract_period_schedule_path(contract_period, schedule))
        expect(flash[:alert]).to eq("Started milestone removed")
      end

      context "and the contract period has started" do
        let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

        it "does not destroy the milestone and redirects with an error" do
          expect { delete destroy_path }.not_to(change(Milestone, :count))

          expect(response).to redirect_to(admin_contract_period_schedule_path(contract_period, schedule))
          expect(flash[:error]).to eq("Milestones cannot be edited once the contract period has started")
        end
      end
    end
  end
end
