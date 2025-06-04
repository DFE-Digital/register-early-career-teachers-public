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

      context "when viewing the index page" do
        before do
          get("/appropriate-body/teachers")
        end

        it "displays the count of open inductions" do
          expect(response.body).to include("2 open inductions")
        end

        it 'renders the page successfully' do
          expect(response).to be_successful
        end

        it 'displays the teachers' do
          expect(response.body).to include(emma.trs_first_name, john.trs_first_name)
        end
      end

      context "when there are more than 50 teachers" do
        let!(:additional_teachers) do
          FactoryBot.create_list(:teacher, 49, trs_first_name: "John", trs_last_name: "Smith").tap do |teachers|
            teachers.each do |teacher|
              FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)
            end
          end
        end

        before do
          get("/appropriate-body/teachers")
        end

        it 'displays pagination' do
          expect(response.body).to include('govuk-pagination')
        end
      end

      context "with a query parameter for a name" do
        before do
          get("/appropriate-body/teachers?q=emma")
        end

        it "returns a successful response" do
          expect(response).to be_successful
        end

        it "includes the matching teacher" do
          expect(response.body).to include(emma.trs_first_name)
        end

        it "excludes non-matching teachers" do
          expect(response.body).not_to include(john.trs_first_name)
        end
      end

      context "with a query parameter for a TRN" do
        let(:teacher_with_trn) { FactoryBot.create(:teacher, trn: '1234567') }

        before do
          FactoryBot.create(:induction_period, :active, teacher: teacher_with_trn, appropriate_body:)
          get("/appropriate-body/teachers?q=1234567")
        end

        it "returns a successful response" do
          expect(response).to be_successful
        end

        it "includes the matching teacher" do
          expect(response.body).to include(teacher_with_trn.trn)
        end

        it "excludes non-matching teachers" do
          expect(response.body).not_to include(emma.trs_first_name)
          expect(response.body).not_to include(john.trs_first_name)
        end
      end
    end
  end
end
