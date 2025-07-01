RSpec.describe 'Admin importing TRS records: registering ECT' do
  include_context 'fake trs api client'

  let(:page_heading) { "Find an early career teacher&#39;s (ECT) record" }

  describe 'GET /admin/register-ect/new' do
    context 'when not signed in' do
      it 'redirects to the sign in page' do
        get('/admin/register-ect/new')

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(sign_in_url)
      end
    end

    context 'when signed in as an admin user' do
      let!(:user) { sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin)) }

      it 'instantiates a new PendingInductionSubmission and renders the page' do
        allow(PendingInductionSubmission).to receive(:new).and_call_original

        get('/admin/register-ect/new')

        expect(response.body).to include(page_heading)
        expect(PendingInductionSubmission).to have_received(:new).once
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /admin/register-ect' do
    context 'when not signed in' do
      it 'redirects to the sign in page' do
        post('/admin/register-ect')

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(sign_in_url)
      end
    end

    context 'when signed in as an admin user' do
      before { allow(Admin::FindECT).to receive(:new).with(any_args).and_call_original }

      let!(:user) { sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin)) }
      let(:birth_year_param) { "2001" }
      let(:trn) { "1234567" }

      let(:search_params) do
        {
          trn:,
          "date_of_birth(3)" => "3",
          "date_of_birth(2)" => "5",
          "date_of_birth(1)" => birth_year_param,
        }
      end

      context "when the submission is valid" do
        it 'passes the parameters to the Admin::FindECT service and redirects' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(Admin::FindECT).to have_received(:new).with(
            pending_induction_submission: PendingInductionSubmission.last
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/admin/check-teacher/\d+/edit\z})
        end
      end

      context "when the teacher already exists" do
        let!(:existing_teacher) { FactoryBot.create(:teacher, trn:) }

        it 'redirects to the already exists error page' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/admin/errors/already-exists/\d+\z})
        end
      end

      context "when the teacher does not have QTS awarded" do
        include_context 'fake trs api client that finds teacher without QTS'

        it 'redirects to the no QTS error page' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/admin/errors/no-qts/\d+\z})
        end
      end

      context "when the teacher is prohibited from teaching" do
        include_context 'fake trs api client that finds teacher prohibited from teaching'

        it 'redirects to the prohibited error page' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/admin/errors/prohibited-from-teaching/\d+\z})
        end
      end

      context "when the teacher has invalid induction status" do
        include_context 'fake trs api client that finds teacher that has passed their induction'

        it 'redirects to the induction status invalid error page' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/admin/errors/induction-status-invalid/\d+\z})
        end
      end

      context "when the teacher is not found" do
        include_context 'fake trs api client that finds nothing'

        it 're-renders the find page and displays the relevant error' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end

      context "when the submission is invalid" do
        let(:birth_year_param) { (Date.current.year - 2).to_s }

        it 're-renders the find page' do
          post(
            '/admin/register-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
        end
      end
    end
  end
end
