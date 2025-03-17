require "rails_helper"

RSpec.describe "Admin::Teachers::RecordPassedOutcome", type: :request do
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) do
    FactoryBot.create(
      :induction_period,
      :active,
      teacher:,
      appropriate_body:,
      started_on: 1.month.ago,
      induction_programme: 'fip'
    )
  end
  let(:valid_params) do
    {
      pending_induction_submission: {
        finished_on: Date.current,
        number_of_terms: 3,
        outcome: 'pass'
      }
    }
  end

  describe "GET /admin/teachers/:teacher_id/record-passed-outcome/new" do
    it "redirects to sign in path" do
      get "/admin/teachers"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/teachers"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as an admin user" do
      include_context 'sign in as DfE user'

      it "renders the new form for a valid teacher" do
        get new_admin_teacher_record_passed_outcome_path(teacher)
        expect(response).to be_successful
        expect(response.body).to include('Record passed outcome')
      end
    end
  end

  describe "POST /admin/teachers/:teacher_id/record-passed-outcome" do
    it "redirects to sign in path" do
      get "/admin/teachers"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/teachers"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as an admin user" do
      include_context 'sign in as DfE user'

      context "with valid params" do
        let(:fake_record_outcome) { double(AppropriateBodies::RecordOutcome, pass!: true) }

        before do
          allow(AppropriateBodies::RecordOutcome).to receive(:new).and_return(fake_record_outcome)
          allow(PendingInductionSubmissions::Build).to receive(:closing_induction_period).and_call_original
        end

        it "creates a new pending induction submission" do
          expect {
            post(
              admin_teacher_record_passed_outcome_path(teacher),
              params: valid_params
            )
          }.to change(PendingInductionSubmission, :count).by(1)
        end

        it "calls the record outcome service and redirects" do
          post(
            admin_teacher_record_passed_outcome_path(teacher),
            params: valid_params
          )

          expect(AppropriateBodies::RecordOutcome).to have_received(:new).with(
            appropriate_body:,
            pending_induction_submission: an_instance_of(PendingInductionSubmission),
            teacher:,
            author: an_instance_of(Sessions::Users::DfEPersona)
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to end_with(admin_teacher_record_passed_outcome_path(teacher))
        end
      end
    end
  end

  describe "GET /admin/teachers/:teacher_id/record-passed-outcome" do
    let!(:induction_period) do
      FactoryBot.create(
        :induction_period,
        :pass,
        teacher:,
        appropriate_body:,
        induction_programme: 'fip'
      )
    end

    it "redirects to sign in path" do
      get "/admin/teachers"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/teachers"
        expect(response.status).to eq(401)
      end
    end

    context "when signed in as an admin user" do
      include_context 'sign in as DfE user'

      it "renders the show page for a valid teacher" do
        get admin_teacher_record_passed_outcome_path(teacher)
        expect(response).to be_successful
      end
    end
  end
end
