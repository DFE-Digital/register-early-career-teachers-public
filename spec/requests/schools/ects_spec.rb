RSpec.describe "ECT summary" do
  let(:ect) { FactoryBot.create(:ect_at_school_period, :unfinished, school:, started_on: 2.years.ago) }
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

      context "when a school's ECT has current and upcoming mentorship periods" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            school:,
            started_on: 2.years.ago
          )
        end

        let(:current_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Moby", trs_last_name: "Dick")
        end
        let(:current_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: ect_at_school_period.started_on,
            school:,
            teacher: current_mentor
          )
        end
        let!(:current_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentor_at_school_period.started_on,
            finished_on: 1.month.from_now,
            mentee: ect_at_school_period,
            mentor: current_mentor_at_school_period
          )
        end

        let(:future_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "John", trs_last_name: "Smith")
        end
        let(:future_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: ect_at_school_period.started_on,
            school:,
            teacher: future_mentor
          )
        end
        let!(:future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            started_on: current_mentorship_period.finished_on.next_day,
            finished_on: current_mentorship_period.finished_on.next_year,
            mentee: ect_at_school_period,
            mentor: future_mentor_at_school_period
          )
        end

        let(:another_future_mentor) do
          FactoryBot.create(:teacher, trs_first_name: "Jane", trs_last_name: "Smith")
        end
        let(:another_future_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            started_on: ect_at_school_period.started_on,
            school:,
            teacher: another_future_mentor
          )
        end
        let!(:another_future_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            started_on: future_mentorship_period.finished_on.next_day,
            mentee: ect_at_school_period,
            mentor: another_future_mentor_at_school_period
          )
        end

        it "displays the current and upcoming mentorship periods" do
          subject
          page = Capybara.string(response.body)

          current_mentor_name = Teachers::Name.new(current_mentor).full_name
          expect(page).to have_text(current_mentor_name)
          expect(page).not_to have_css(".govuk-hint", text: current_mentor_name)

          future_mentor_name = Teachers::Name.new(future_mentor).full_name
          future_mentor_start_date = future_mentorship_period.started_on.to_fs(:govuk)
          expect(page).to have_css(
            ".govuk-hint",
            text: "#{future_mentor_name} (from #{future_mentor_start_date})"
          )

          another_future_mentor_name = Teachers::Name.new(another_future_mentor).full_name
          another_future_mentor_start_date = another_future_mentorship_period.started_on.to_fs(:govuk)
          expect(page).to have_css(
            ".govuk-hint",
            text: "#{another_future_mentor_name} (from #{another_future_mentor_start_date})"
          )
        end
      end
    end
  end

  describe "GET #show" do
    let!(:training_period) do
      FactoryBot.create(:training_period, :unfinished, ect_at_school_period: ect, started_on: 1.year.ago)
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
        let!(:training_period) { nil }
        let(:ect) { FactoryBot.create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 6.months.from_now) }
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
        let!(:training_period) { nil }
        let(:ect) { FactoryBot.create(:ect_at_school_period, school:, started_on: 1.year.ago, finished_on: 6.months.from_now) }
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
