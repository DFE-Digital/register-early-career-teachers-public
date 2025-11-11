describe "Schools::ECTs::ChangeTrainingProgrammeWizardController", :enable_schools_interface do
  let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
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
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      :for_ect,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on
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
    let(:new_training_programme) { "provider_led" }
    let(:params) { { edit: { training_programme: new_training_programme } } }

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

      context "when the training programme pattern is missing" do
        let(:new_training_programme) { "" }

        it "returns unprocessable_content" do
          post(path_for_step("edit"), params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when changing from provider-led to school-led training" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :provider_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end
        let(:new_training_programme) { "school_led" }

        it "switches the training to school-led" do
          post(path_for_step("edit"), params:)

          follow_redirect!

          ect_at_school_period.reload
          expect(ect_at_school_period).to be_provider_led_training_programme

          post(path_for_step("check-answers"))

          ect_at_school_period.reload
          expect(ect_at_school_period).to be_school_led_training_programme
          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "creates an event only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_training_programme_updated_event!)

          post(path_for_step("edit"), params:)

          expect(Events::Record).not_to have_received(:record_teacher_training_programme_updated_event!)
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Events::Record).to have_received(:record_teacher_training_programme_updated_event!)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when changing from school-led to provider-led training" do
        let(:lead_provider) { FactoryBot.create(:lead_provider) }
        let!(:active_lead_provider) do
          FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        end
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :school_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end
        let(:new_training_programme) { "provider_led" }
        let(:lead_provider_params) do
          { lead_provider: { lead_provider_id: lead_provider.id } }
        end

        it "switches the training to provider-led" do
          post(path_for_step("edit"), params:)

          follow_redirect!

          ect_at_school_period.reload
          expect(ect_at_school_period).to be_school_led_training_programme

          post(path_for_step("lead-provider"), params: lead_provider_params)

          follow_redirect!

          ect_at_school_period.reload
          expect(ect_at_school_period).to be_school_led_training_programme

          post(path_for_step("check-answers"))

          ect_at_school_period.reload
          expect(ect_at_school_period).to be_provider_led_training_programme
          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "creates an event only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_training_programme_updated_event!)

          post(path_for_step("edit"), params:)

          expect(Events::Record).not_to have_received(:record_teacher_training_programme_updated_event!)
          expect(response).to redirect_to(path_for_step("lead-provider"))

          follow_redirect!

          post(path_for_step("lead-provider"), params: lead_provider_params)

          expect(Events::Record).not_to have_received(:record_teacher_training_programme_updated_event!)
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Events::Record).to have_received(:record_teacher_training_programme_updated_event!)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}/change-training-programme/#{step}"
  end
end
