describe "Schools::Mentors::ChangeLeadProviderWizard Requests", :enable_schools_interface do
  let(:started_on) { 3.months.ago.to_date }
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher:,
      school:,
      email: "mentor@example.com"
    )
  end

  let!(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:, school_partnership:) }
  let(:old_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:new_lead_provider) { lead_provider }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: old_lead_provider, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, contract_period:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

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
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:params) { { edit: { lead_provider_id: lead_provider.id } } }

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
      let!(:user) { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          post(path_for_step("nope"), params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the lead provider has changed" do
        let(:params) { { edit: { lead_provider_id: lead_provider.id } } }

        it "uses the service to change the lead provider" do
          allow(MentorAtSchoolPeriods::ChangeLeadProvider)
            .to receive(:call)
            .and_return(true)

          post(path_for_step("edit"), params:)

          expect(MentorAtSchoolPeriods::ChangeLeadProvider)
            .not_to have_received(:call)

          follow_redirect!

          post path_for_step("check-answers")

          expect(MentorAtSchoolPeriods::ChangeLeadProvider)
            .to have_received(:call)
            .with(
              mentor_at_school_period,
              new_lead_provider:,
              old_lead_provider:,
              author: an_instance_of(Sessions::Users::SchoolPersona)
            )
        end

        it "updates the lead provider only after confirmation" do
          post(path_for_step("edit"), params:)

          follow_redirect!

          post(path_for_step("check-answers"))

          expect(training_period.reload.finished_on).to eq(Date.current)
          new_training_period = mentor_at_school_period.training_periods.ongoing.first
          expect(new_training_period.expression_of_interest.lead_provider).to eq(lead_provider)

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

      context "when the lead provider is unchanged" do
        let(:params) { { edit: { lead_provider_id: old_lead_provider.id } } }

        it "returns unprocessable_content" do
          post(path_for_step("edit"), params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/mentors/#{mentor_at_school_period.id}/change-lead-provider/#{step}"
  end
end
