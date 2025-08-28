RSpec.describe 'ECT summary' do
  let(:ect) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:school) { FactoryBot.create(:school) }

  describe "GET #index" do
    context "when not signed in" do
      it "redirects to the rot page" do
        get schools_ects_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-school user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        get schools_ects_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a school user" do
      before { sign_in_as(:school_user, school:) }

      it "returns ok" do
        get schools_ects_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #show' do
    let!(:training_period) do
      FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect)
    end

    describe 'finding the ECT at school period' do
      subject { response }

      context 'when signed in as user from the same school' do
        before do
          sign_in_as(:school_user, school:)
          get("/school/ects/#{ect.id}")
        end

        it { is_expected.to be_successful }
      end

      context 'when signed in as user from another school' do
        before do
          sign_in_as(:school_user, school: FactoryBot.create(:school))
          get("/school/ects/#{ect.id}")
        end

        it { is_expected.to be_not_found }
      end

      context "when there is no training period" do
        let!(:training_period) { nil }

        before do
          sign_in_as(:school_user, school:)
          get("/school/ects/#{ect.id}")
        end

        it { is_expected.to be_successful }
      end
    end
  end
end
