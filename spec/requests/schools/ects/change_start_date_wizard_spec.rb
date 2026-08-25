RSpec.describe "Schools::ECTs::ChangeStartDateWizardController" do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      school:,
      teacher:,
      started_on: Date.new(2025, 9, 1)
    )
  end

  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :provider_led,
      :unfinished,
      :for_ect,
      ect_at_school_period:,
      started_on: Date.new(2025, 9, 1)
    )
  end

  describe "GET edit" do
    subject(:get_edit) do
      get path_for_step("edit")
    end

    context "when not signed in" do
      it "redirects to the root page" do
        get_edit

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-school user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        get_edit

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a school user" do
      before do
        sign_in_as(:school_user, school:)
      end

      context "when the ECT is eligible" do
        it "returns ok" do
          get_edit

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the ECT has multiple training periods" do
        before do
          training_period.update!(
            finished_on: Date.new(2025, 12, 31)
          )

          FactoryBot.create(
            :training_period,
            :provider_led,
            :unfinished,
            :for_ect,
            ect_at_school_period:,
            started_on: Date.new(2026, 1, 1)
          )
        end

        it "returns not found" do
          get_edit

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the ECT has multiple mentorship periods" do
        let(:first_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2025, 9, 1)
          )
        end

        let(:second_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school:,
            started_on: Date.new(2025, 9, 1)
          )
        end

        before do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: first_mentor_at_school_period,
            started_on: Date.new(2025, 9, 1),
            finished_on: Date.new(2025, 12, 31)
          )

          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentee: ect_at_school_period,
            mentor: second_mentor_at_school_period,
            started_on: Date.new(2026, 1, 1)
          )
        end

        it "returns not found" do
          get_edit

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the ECT belongs to another school" do
        let(:other_school) { FactoryBot.create(:school) }

        before do
          sign_in_as(
            :school_user,
            school: other_school
          )
        end

        it "returns not found" do
          get_edit

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST edit" do
    subject(:post_edit) do
      post path_for_step("edit"), params:
    end

    let(:new_start_date) { Date.current - 1.day }

    let(:params) do
      {
        edit: {
          "start_date(1i)" => new_start_date.year.to_s,
          "start_date(2i)" => new_start_date.month.to_s,
          "start_date(3i)" => new_start_date.day.to_s
        }
      }
    end

    let(:contract_period) do
      FactoryBot.build_stubbed(
        :contract_period,
        enabled: true
      )
    end

    before do
      sign_in_as(:school_user, school:)

      allow(ContractPeriod)
        .to receive(:containing_date)
        .and_call_original

      allow(ContractPeriod)
        .to receive(:containing_date)
        .with(new_start_date)
        .and_return(contract_period)
    end

    it "redirects to check answers" do
      post_edit

      expect(response)
        .to redirect_to(path_for_step("check-answers"))
    end

    it "shows the confirmation page" do
      post_edit
      post path_for_step("check-answers")
      follow_redirect!

      teacher_full_name = Teachers::Name.new(teacher).full_name

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "School start date updated for #{teacher_full_name}"
      )
      expect(response.body).to include("school start date")
      expect(response.body).to include(
        new_start_date.to_fs(:govuk)
      )
      expect(response.body).to include(
        "Back to #{teacher_full_name}"
      )
      expect(response.body).to include(
        schools_ect_path(ect_at_school_period)
      )
    end

    it "shows the check-answers page" do
      post_edit
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check and confirm change")
      expect(response.body).to include("Early career teacher")
      expect(response.body).to include(
        Teachers::Name.new(teacher).full_name
      )
      expect(response.body).to include("Current school start date")
      expect(response.body).to include(
        ect_at_school_period.started_on.to_fs(:govuk)
      )
      expect(response.body).to include("New school start date")
      expect(response.body).to include(
        new_start_date.to_fs(:govuk)
      )
      expect(response.body).to include("Confirm change")
      expect(response.body).to include(
        schools_ect_path(ect_at_school_period)
      )
    end

    it "does not change the school start date before confirmation" do
      expect { post_edit }
        .not_to(change { ect_at_school_period.reload.started_on })
    end

    context "when the start date is invalid" do
      let(:params) do
        {
          edit: {
            "start_date(1i)" => "2026",
            "start_date(2i)" => "2",
            "start_date(3i)" => "30"
          }
        }
      end

      it "returns unprocessable content" do
        post_edit

        expect(response)
          .to have_http_status(:unprocessable_content)
      end

      it "does not change the school start date" do
        expect { post_edit }
          .not_to(change { ect_at_school_period.reload.started_on })
      end
    end

    context "when the date is in an unopened contract period" do
      let(:new_start_date) { Date.current + 6.months }

      let(:contract_period) do
        FactoryBot.build_stubbed(
          :contract_period,
          enabled: false
        )
      end

      it "redirects to the cannot-use-date page" do
        post_edit

        expect(response)
          .to redirect_to(path_for_step("cannot-use-date"))
      end

      it "does not change the school start date" do
        expect { post_edit }
          .not_to(change { ect_at_school_period.reload.started_on })
      end

      it "shows support and go-back links" do
        post_edit
        follow_redirect!

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("You cannot use this date")
        expect(response.body).to include("contact support")
        expect(response.body).to include(
          new_schools_support_query_path
        )
        expect(response.body).to include("Go back")
        expect(response.body).to include(
          path_for_step("edit")
        )
      end
    end
  end

  describe "POST check answers" do
    subject(:post_check_answers) do
      post path_for_step("check-answers")
    end

    let(:new_start_date) { Date.current - 1.day }

    let(:edit_params) do
      {
        edit: {
          "start_date(1i)" => new_start_date.year.to_s,
          "start_date(2i)" => new_start_date.month.to_s,
          "start_date(3i)" => new_start_date.day.to_s
        }
      }
    end

    let(:contract_period) do
      FactoryBot.build_stubbed(
        :contract_period,
        enabled: true
      )
    end

    before do
      sign_in_as(:school_user, school:)

      allow(ContractPeriod)
        .to receive(:containing_date)
        .and_call_original

      allow(ContractPeriod)
        .to receive(:containing_date)
        .with(new_start_date)
        .and_return(contract_period)

      allow(Events::Record)
        .to receive(
          :record_teacher_school_start_date_updated_event!
        )

      post path_for_step("edit"), params: edit_params
    end

    it "updates the school and training period start dates" do
      expect { post_check_answers }
        .to change { ect_at_school_period.reload.started_on }
        .from(Date.new(2025, 9, 1))
        .to(new_start_date)
        .and change { training_period.reload.started_on }
        .from(Date.new(2025, 9, 1))
        .to(new_start_date)
    end

    it "records the event only after confirmation" do
      expect(Events::Record)
        .not_to have_received(
          :record_teacher_school_start_date_updated_event!
        )

      post_check_answers

      expect(Events::Record)
        .to have_received(
          :record_teacher_school_start_date_updated_event!
        )
        .once
    end

    it "redirects to the confirmation page" do
      post_check_answers

      expect(response)
        .to redirect_to(path_for_step("confirmation"))
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}" \
      "/change-school-start-date/#{step}"
  end
end
