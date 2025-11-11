describe "Schools::ECTs::ChangeMentorWizardController", :enable_schools_interface do
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
  let(:mentor_teacher) { FactoryBot.create(:teacher) }
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: mentor_teacher,
      school:,
      started_on: ect_at_school_period.started_on - 1.month
    )
  end
  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: ect_at_school_period,
      mentor: mentor_at_school_period,
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

      context "when there are no mentors registered at the school" do
        let(:mentorship_period) { nil }

        it "redirects to the register mentor wizard" do
          get path_for_step("edit")
          expect(response).to redirect_to(
            schools_register_mentor_wizard_start_path(ect_id: ect_at_school_period.id, new_mentor_requested: true)
          )
        end
      end

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
    let(:other_mentor_teacher) { FactoryBot.create(:teacher) }
    let(:other_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        teacher: other_mentor_teacher,
        school:,
        started_on: ect_at_school_period.started_on - 1.week
      )
    end
    let(:mentor_at_school_period_id) { other_mentor_at_school_period.id }
    let(:params) { { edit: { mentor_at_school_period_id: } } }

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

      context "when the ECT is being mentored by a new mentor" do
        # The form uses 0 to indicate a new mentor is being requested and redirects accordingly
        let(:mentor_at_school_period_id) { 0 }

        it "redirects to the register mentor wizard" do
          post(path_for_step("edit"), params:)
          expect(response).to redirect_to(
            schools_register_mentor_wizard_start_path(ect_id: ect_at_school_period.id, new_mentor_requested: true)
          )
        end
      end

      context "when the ECT is undergoing school-led training" do
        let!(:ect_training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :school_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "assigns a mentor without training" do
          post(path_for_step("edit"), params:)

          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          expect { post(path_for_step("check-answers")) }
            .not_to change(TrainingPeriod, :count)

          ect_at_school_period.reload
          expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
            .to eq(other_mentor_at_school_period)
          expect(other_mentor_at_school_period.training_periods)
            .to be_empty
          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "records the relevant events only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)
          allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!)
          allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!)

          post(path_for_step("edit"), params:)
          follow_redirect!
          post(path_for_step("check-answers"))

          expect(Events::Record).not_to have_received(:record_teacher_starts_training_period_event!)
          expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!)
          expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!)

          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when the ECT is undergoing provider-led training" do
        let!(:ect_training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :provider_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        before do
          ect_training_period.active_lead_provider.update!(contract_period:)
        end

        context "when the mentor has a provider-led training period" do
          let!(:other_mentor_training_period) do
            FactoryBot.create(
              :training_period,
              :ongoing,
              :provider_led,
              :for_mentor,
              mentor_at_school_period: other_mentor_at_school_period,
              started_on: other_mentor_at_school_period.started_on
            )
          end

          it "assigns a mentor without training" do
            post(path_for_step("edit"), params:)

            expect(response).to redirect_to(path_for_step("check-answers"))

            follow_redirect!

            expect { post(path_for_step("check-answers")) }
              .not_to change(TrainingPeriod, :count)

            ect_at_school_period.reload
            expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
              .to eq(other_mentor_at_school_period)
            expect(other_mentor_at_school_period.training_periods)
              .to contain_exactly(other_mentor_training_period)
            expect(response).to redirect_to(path_for_step("confirmation"))
          end

          it "records the relevant events only after confirmation" do
            allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)
            allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!)
            allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!)

            post(path_for_step("edit"), params:)
            follow_redirect!
            post(path_for_step("check-answers"))

            expect(Events::Record).not_to have_received(:record_teacher_starts_training_period_event!)
            expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!)
            expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!)

            expect(response).to redirect_to(path_for_step("confirmation"))
          end
        end

        context "when the mentor is ineligible for funding" do
          let(:other_mentor_teacher) do
            FactoryBot.create(:teacher, :ineligible_for_mentor_funding)
          end

          it "assigns a mentor without training" do
            post(path_for_step("edit"), params:)

            expect(response).to redirect_to(path_for_step("check-answers"))

            follow_redirect!

            expect { post(path_for_step("check-answers")) }
              .not_to change(TrainingPeriod, :count)

            ect_at_school_period.reload
            expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
              .to eq(other_mentor_at_school_period)
            expect(other_mentor_at_school_period.training_periods)
              .to be_empty
            expect(response).to redirect_to(path_for_step("confirmation"))
          end

          it "records the relevant events only after confirmation" do
            allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)
            allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!)
            allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!)

            post(path_for_step("edit"), params:)
            follow_redirect!
            post(path_for_step("check-answers"))

            expect(Events::Record).not_to have_received(:record_teacher_starts_training_period_event!)
            expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!)
            expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!)

            expect(response).to redirect_to(path_for_step("confirmation"))
          end
        end

        context "when the mentor is eligible for funding" do
          context "when the mentor has the same lead provider" do
            it "assigns a mentor with training" do
              post(path_for_step("edit"), params:)

              expect(response).to redirect_to(path_for_step("review-mentor-eligibility"))

              follow_redirect!

              review_mentor_eligibility_params = { review_mentor_eligibility: { accepting_current_lead_provider: true } }
              post(path_for_step("review-mentor-eligibility"), params: review_mentor_eligibility_params)

              expect(response).to redirect_to(path_for_step("check-answers"))

              follow_redirect!

              expect { post(path_for_step("check-answers")) }
                .to change(TrainingPeriod, :count).by(1)

              ect_at_school_period.reload
              new_training_period = TrainingPeriod.last
              expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
                .to eq(other_mentor_at_school_period)
              expect(other_mentor_at_school_period.training_periods)
                .to contain_exactly(new_training_period)
              expect(new_training_period.lead_provider)
                .to eq(ect_training_period.lead_provider)
              expect(response).to redirect_to(path_for_step("confirmation"))
            end

            it "records the relevant events only after confirmation" do
              allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)
              allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!)
              allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!)

              post(path_for_step("edit"), params:)
              follow_redirect!
              review_mentor_eligibility_params = { review_mentor_eligibility: { accepting_current_lead_provider: true } }
              post(path_for_step("review-mentor-eligibility"), params: review_mentor_eligibility_params)
              follow_redirect!
              post(path_for_step("check-answers"))

              expect(Events::Record).to have_received(:record_teacher_starts_training_period_event!)
              expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!)
              expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!)

              expect(response).to redirect_to(path_for_step("confirmation"))
            end
          end

          context "when the mentor has a different lead provider" do
            let(:other_lead_provider) do
              FactoryBot.create(:active_lead_provider, contract_period:)
                .lead_provider
            end

            it "assigns a mentor with training" do
              post(path_for_step("edit"), params:)

              expect(response).to redirect_to(path_for_step("review-mentor-eligibility"))

              follow_redirect!

              get(path_for_step("lead-provider"))

              lead_provider_params = {
                lead_provider: { lead_provider_id: other_lead_provider.id }
              }
              post(path_for_step("lead-provider"), params: lead_provider_params)

              expect(response).to redirect_to(path_for_step("check-answers"))

              follow_redirect!

              expect { post(path_for_step("check-answers")) }
                .to change(TrainingPeriod, :count).by(1)

              ect_at_school_period.reload
              new_training_period = TrainingPeriod.last
              expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
                .to eq(other_mentor_at_school_period)
              expect(other_mentor_at_school_period.training_periods)
                .to contain_exactly(new_training_period)
              expect(new_training_period.expression_of_interest_lead_provider)
                .to eq(other_lead_provider)
              expect(response).to redirect_to(path_for_step("confirmation"))
            end

            it "records the relevant events only after confirmation" do
              allow(Events::Record).to receive(:record_teacher_starts_training_period_event!)
              allow(Events::Record).to receive(:record_teacher_starts_being_mentored_event!)
              allow(Events::Record).to receive(:record_teacher_starts_mentoring_event!)

              post(path_for_step("edit"), params:)
              follow_redirect!
              lead_provider_params = {
                lead_provider: { lead_provider_id: other_lead_provider.id }
              }
              post(path_for_step("lead-provider"), params: lead_provider_params)
              follow_redirect!
              post(path_for_step("check-answers"))

              expect(Events::Record).to have_received(:record_teacher_starts_training_period_event!)
              expect(Events::Record).to have_received(:record_teacher_starts_being_mentored_event!)
              expect(Events::Record).to have_received(:record_teacher_starts_mentoring_event!)

              expect(response).to redirect_to(path_for_step("confirmation"))
            end
          end
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}/change-mentor/#{step}"
  end
end
