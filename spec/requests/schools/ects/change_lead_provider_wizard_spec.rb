describe "Schools::ECTs::ChangeLeadProviderWizardController", :enable_schools_interface do
  let(:contract_period) { FactoryBot.create(:contract_period, :current, :with_schedules) }
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher:,
      school:,
      started_on: contract_period.started_on + 2.months
    )
  end
  let(:lead_provider) do
    FactoryBot.create(:lead_provider, name: "Testing Provider")
  end
  let(:active_lead_provider) do
    FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      :for_ect,
      :provider_led,
      :with_only_expression_of_interest,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on,
      expression_of_interest: active_lead_provider
    )
  end
  let(:other_lead_provider) do
    FactoryBot.create(:lead_provider, name: "Other Lead Provider")
  end
  let!(:other_active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      contract_period:,
      lead_provider: other_lead_provider
    )
  end

  describe "GET #new" do
    context "when not signed in" do
      it "redirects to the root page" do
        get path_for_step("edit")

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        get path_for_step("edit")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      before { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          get path_for_step("nope")

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the current_step is valid" do
        it "returns ok" do
          get path_for_step("edit")

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST #create" do
    let(:lead_provider_id) { other_lead_provider.id }
    let(:params) { { edit: { lead_provider_id: } } }

    context "when not signed in" do
      it "redirects to the root path" do
        post(path_for_step("edit"), params:)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        post(path_for_step("edit"), params:)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      let(:school_user) { FactoryBot.create(:school_user, school:) }

      before { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          post(path_for_step("nope"), params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the lead provider id is missing" do
        let(:lead_provider_id) { "" }

        it "returns unprocessable_content" do
          post(path_for_step("edit"), params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the lead provider id is invalid" do
        let(:lead_provider_id) { "invalid" }

        it "returns unprocessable_content" do
          post(path_for_step("edit"), params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the lead provider id is valid" do
        let(:lead_provider_id) { other_lead_provider.id }

        it "updates the lead provider only after confirmation" do
          post(path_for_step("edit"), params:)

          follow_redirect!

          training = current_training_for(ect_at_school_period.reload)
          expect(training.lead_provider_via_school_partnership_or_eoi)
            .to eq(lead_provider)

          post(path_for_step("check-answers"))

          training = current_training_for(ect_at_school_period.reload)
          expect(training.lead_provider_via_school_partnership_or_eoi)
            .to eq(other_lead_provider)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "creates an event only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_training_lead_provider_updated_event!)

          post(path_for_step("edit"), params:)

          expect(Events::Record).not_to have_received(:record_teacher_training_lead_provider_updated_event!)
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Events::Record).to have_received(:record_teacher_training_lead_provider_updated_event!)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when the ECT is school-led" do
        let(:training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :school_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "returns not found for the edit get step" do
          get path_for_step("edit")
          expect(response).to have_http_status(:not_found)
        end

        it "returns not found for the edit post step" do
          post path_for_step("edit")
          expect(response).to have_http_status(:not_found)
        end

        it "returns not found for the check-answers get step" do
          get path_for_step("check-answers")
          expect(response).to have_http_status(:not_found)
        end

        it "returns not found for the check-answers post step" do
          post path_for_step("check-answers")
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}/change-lead-provider/#{step}"
  end

  def current_training_for(ect_at_school_period)
    ECTAtSchoolPeriods::CurrentTraining.new(ect_at_school_period)
  end
end
