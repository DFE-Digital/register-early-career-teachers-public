RSpec.describe "Appropriate Body teacher index page", type: :request do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'GET /appropriate-body/teachers' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
      let!(:emma) { FactoryBot.create(:teacher, trs_first_name: 'Emma') }
      let!(:john) { FactoryBot.create(:teacher, trs_first_name: 'John') }

      before do
        [emma, john].each do |teacher|
          FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)
        end
      end

      it "displays the count of claimed inductions" do
        get("/appropriate-body/teachers")
        expect(response.body).to include("2 claimed inductions")
      end

      context "when there are more than 10 claimed ECTs" do
        it 'displays pagination' do
          FactoryBot.create_list(:teacher, 11, trs_first_name: "John", trs_last_name: "Smith").each do |teacher|
            FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)
          end

          get("/appropriate-body/teachers")

          expect(response.body).to include('govuk-pagination')
        end
      end

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/appropriate-body/teachers")

        expect(response).to be_successful
        expect(response.body).to include(emma.trs_first_name, john.trs_first_name)
      end

      context "with a query parameter" do
        it "filters the list of teachers" do
          get("/appropriate-body/teachers?q=emma")
          expect(response).to be_successful

          expect(response.body).to include(emma.trs_first_name)
          expect(response.body).not_to include(john.trs_first_name)
        end
      end
    end
  end
end
