RSpec.describe "Admin::Teachers::Schools", type: :request do
  let(:teacher) { FactoryBot.create(:teacher) }

  describe "GET /admin/teachers/:teacher_id/school" do
    it "redirects to sign in path" do
      get admin_teacher_school_path(teacher)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get admin_teacher_school_path(teacher)
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get admin_teacher_school_path(teacher)
        expect(response).to have_http_status(:success)
      end

      context "when the schools interface flag is enabled" do
        before do
          allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
        end

        it "renders the teacher navigation" do
          get admin_teacher_school_path(teacher)
          expect(response.body).to include("x-govuk-secondary-navigation")
        end
      end

      context "when the schools interface flag is disabled" do
        before do
          allow(Rails.application.config).to receive(:enable_schools_interface).and_return(false)
        end

        it "does not render the teacher navigation" do
          get admin_teacher_school_path(teacher)
          expect(response.body).not_to include("x-govuk-secondary-navigation")
        end
      end

      context "when the teacher has an ECT school period" do
        let(:ect_period) { FactoryBot.create(:ect_at_school_period) }
        let(:teacher) { ect_period.teacher }

        it "shows the ECT history section" do
          get admin_teacher_school_path(teacher)
          expect(response.body).to include("ECT history")
          expect(response.body).to include(ect_period.school.name)
        end
      end

      context "when the teacher has a mentor school period" do
        let(:mentor_period) { FactoryBot.create(:mentor_at_school_period) }
        let(:teacher) { mentor_period.teacher }

        it "shows the mentor history section" do
          get admin_teacher_school_path(teacher)
          expect(response.body).to include("Mentor history")
          expect(response.body).to include(mentor_period.school.name)
        end
      end

      context "when the teacher has no school periods" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it "shows the empty state message" do
          get admin_teacher_school_path(teacher)
          expect(response.body).to include("There is no school history recorded for this teacher")
        end
      end

      context "with multiple ECT school periods" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:older_started_on) { 2.years.ago.to_date }
        let(:newer_started_on) { 1.year.ago.to_date }
        let!(:older_period) do
          FactoryBot.create(:ect_at_school_period, teacher:, started_on: older_started_on, finished_on: older_started_on + 1.year)
        end
        let!(:newer_period) do
          FactoryBot.create(:ect_at_school_period, teacher:, started_on: newer_started_on, finished_on: newer_started_on + 1.year)
        end

        it "orders the periods with the most recent first" do
          get admin_teacher_school_path(teacher)

          expect(response.body).to include(newer_started_on.to_fs(:govuk))
          expect(response.body).to include(older_started_on.to_fs(:govuk))
          expect(response.body.index(newer_started_on.to_fs(:govuk))).to be < response.body.index(older_started_on.to_fs(:govuk))
        end
      end

      context "with multiple mentor school periods" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:older_started_on) { 3.years.ago.to_date }
        let(:newer_started_on) { 6.months.ago.to_date }
        let!(:older_period) do
          FactoryBot.create(:mentor_at_school_period, teacher:, started_on: older_started_on, finished_on: older_started_on + 6.months)
        end
        let!(:newer_period) do
          FactoryBot.create(:mentor_at_school_period, teacher:, started_on: newer_started_on, finished_on: newer_started_on + 6.months)
        end

        it "orders the periods with the most recent first" do
          get admin_teacher_school_path(teacher)

          expect(response.body).to include(newer_started_on.to_fs(:govuk))
          expect(response.body).to include(older_started_on.to_fs(:govuk))
          expect(response.body.index(newer_started_on.to_fs(:govuk))).to be < response.body.index(older_started_on.to_fs(:govuk))
        end
      end
    end
  end
end
