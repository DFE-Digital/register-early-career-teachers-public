RSpec.describe "Assign existing mentor wizard" do
  include_context "safe_schedules"

  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { mid_year }
  let(:ect)    { FactoryBot.create(:ect_at_school_period, :unfinished, school:, started_on:) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on:) }
  let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }

  before do
    school_partnership = FactoryBot.create(:school_partnership, school:)
    school_partnership.lead_provider_delivery_partnership.framework_agreement.update!(contract_period:)

    FactoryBot.create(:training_period,
                      :unfinished,
                      :provider_led,
                      ect_at_school_period: ect,
                      started_on:,
                      school_partnership:)
  end

  def kickoff_wizard!(mentor_at_school_period = mentor)
    allow(Teachers::MentorFundingEligibility).to receive(:new)
      .with(trn: mentor_at_school_period.teacher.trn)
      .and_return(instance_double(Teachers::MentorFundingEligibility, eligible?: true))

    post(
      "/school/ects/#{ect.id}/mentorship",
      params: { schools_assign_mentor_form: { mentor_id: mentor_at_school_period.id } }
    )
  end

  describe "GET /school/assign-existing-mentor/:step" do
    subject { get schools_assign_existing_mentor_wizard_review_mentor_eligibility_path }

    it_behaves_like "an induction redirectable route"
    it_behaves_like "a route blocked when the registration window is closed"

    context "when signed in as a school user" do
      before { sign_in_as(:school_user, school:) }

      context "when the wizard is not yet started" do
        it "redirects to the ECTs home page" do
          subject
          expect(response).to redirect_to(schools_ects_home_path)
        end
      end

      context "when the mentor is eligible for funding" do
        before { kickoff_wizard! }

        it "renders the review_mentor_eligibility step" do
          subject
          expect(response).to have_http_status(:ok)
        end

        it "renders the lead_provider step" do
          get schools_assign_existing_mentor_wizard_lead_provider_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "when visiting an invalid step" do
        it "renders a 404 page" do
          get "/school/assign-existing-mentor/fake-step"
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST /school/assign-existing-mentor/:step" do
    subject { post schools_assign_existing_mentor_wizard_review_mentor_eligibility_path }

    before { sign_in_as(:school_user, school:) }

    it_behaves_like "an induction redirectable route"
    it_behaves_like "a route blocked when the registration window is closed"

    context "when the wizard is not started" do
      it "redirects to the ECTs home page" do
        subject
        expect(response).to redirect_to(schools_ects_home_path)
      end
    end

    context "when mentor is eligible for funding" do
      before { kickoff_wizard! }

      it "redirects to the confirmation step" do
        subject
        expect(response).to redirect_to(schools_assign_existing_mentor_wizard_confirmation_path)
      end
    end

    context "when selecting a different lead provider" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:params) { { lead_provider: { lead_provider_id: lead_provider.id } } }

      before do
        FactoryBot.create(:framework_agreement, lead_provider:, contract_period:)
        kickoff_wizard!
        post schools_assign_existing_mentor_wizard_lead_provider_path, params:
      end

      it "trains the mentor with the selected lead provider and redirects to the confirmation step" do
        expect(response).to redirect_to(schools_assign_existing_mentor_wizard_confirmation_path)
        expect(mentor.training_periods.sole.expression_of_interest.lead_provider).to eq(lead_provider)
      end

      it "renders the confirmation step" do
        follow_redirect!

        expect(response).to have_http_status(:ok)
      end

      context "when no lead provider is selected" do
        let(:params) { {} }

        it "re-renders the step with an error and does not assign the mentor" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Select a lead provider to contact your school")
          expect(mentor.mentorship_periods).to be_empty
        end
      end

      context "when the wizard is started again for another mentor" do
        let(:other_mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on:) }

        before { kickoff_wizard!(other_mentor) }

        it "does not preselect the previously selected lead provider" do
          get schools_assign_existing_mentor_wizard_lead_provider_path

          expect(response.body).to include(Teachers::Name.new(other_mentor.teacher).full_name)
          expect(response.body).not_to include('checked="checked"')
        end
      end
    end

    context "when visiting an invalid step" do
      it "renders a 404 page" do
        post "/school/assign-existing-mentor/fake-step"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
