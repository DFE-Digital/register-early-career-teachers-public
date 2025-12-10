RSpec.describe "ECT summary", :enable_schools_interface do
  let(:ect) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:school) { FactoryBot.create(:school) }

  describe "GET #index" do
    subject { get schools_ects_path }

    it_behaves_like "an induction redirectable route"

    context "when not signed in" do
      it "redirects to the rot page" do
        subject

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-school user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a school user" do
      before { sign_in_as(:school_user, school:) }

      it "returns ok" do
        subject

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #show" do
    let!(:training_period) do
      FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect, started_on: 1.year.ago)
    end

    describe "finding the ECT at school period" do
      subject { get("/school/ects/#{ect.id}") }

      it_behaves_like "an induction redirectable route"

      context "when signed in as user from the same school" do
        before do
          sign_in_as(:school_user, school:)
          subject
        end

        it "returns ok" do
          subject

          expect(response).to have_http_status(:ok)
        end
      end

      context "when signed in as user from another school" do
        before do
          sign_in_as(:school_user, school: FactoryBot.create(:school))
          subject
        end

        it "returns not found" do
          subject

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when there is no training period" do
        let!(:training_period) { nil }

        before do
          sign_in_as(:school_user, school:)
          subject
        end

        it "returns ok" do
          subject

          expect(response).to have_http_status(:ok)
        end
      end

      context "when accessing old period ID from different school" do
        let(:other_school) { FactoryBot.create(:school) }
        let(:teacher) { ect.teacher }
        let!(:old_period) { FactoryBot.create(:ect_at_school_period, teacher:, school: other_school, started_on: 3.years.ago) }

        before do
          sign_in_as(:school_user, school: other_school)
          subject
        end

        it "returns not found" do
          expect(response).to be_not_found
          expect(response.status).to eq(404)
        end
      end

      context "when accessing future ECT period at current school" do
        let(:teacher) { ect.teacher }
        let!(:future_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: 1.year.from_now) }

        before do
          sign_in_as(:school_user, school:)
          get("/school/ects/#{future_period.id}")
        end

        it "allows access to future periods at the same school" do
          expect(response).to be_successful
          expect(response.status).to eq(200)
        end
      end

      context "when accessing future ECT period from different school" do
        let(:other_school) { FactoryBot.create(:school) }
        let(:teacher) { ect.teacher }
        let!(:future_period) { FactoryBot.create(:ect_at_school_period, teacher:, school: other_school, started_on: 1.year.from_now) }

        before do
          sign_in_as(:school_user, school:)
          get("/school/ects/#{future_period.id}")
        end

        it "returns not found" do
          expect(response).to be_not_found
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
