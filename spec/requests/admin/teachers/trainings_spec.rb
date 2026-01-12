RSpec.describe "Admin::Teachers::Training", type: :request do
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    allow(API::TeacherSerializer)
    .to receive(:render)
    .with(
      teacher,
      root: "data",
      lead_provider_id: anything
    )
    .and_return('{"data":{"id":123}}')
  end

  describe "GET /admin/teachers/:teacher_id/training" do
    it "redirects to sign in path" do
      get admin_teacher_training_path(teacher)
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get admin_teacher_training_path(teacher)
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get admin_teacher_training_path(teacher)
        expect(response).to have_http_status(:success)
      end

      context "when the schools interface flag is enabled" do
        before do
          allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
        end

        it "renders the teacher navigation" do
          get admin_teacher_training_path(teacher)
          expect(response.body).to include("x-govuk-secondary-navigation")
        end
      end

      context "when the schools interface flag is disabled" do
        before do
          allow(Rails.application.config).to receive(:enable_schools_interface).and_return(false)
        end

        it "does not render the teacher navigation" do
          get admin_teacher_training_path(teacher)
          expect(response.body).not_to include("x-govuk-secondary-navigation")
        end
      end

      context "when the teacher has an ECT training period" do
        let(:ect_training_period) { FactoryBot.create(:training_period) }
        let(:teacher) { ect_training_period.ect_at_school_period.teacher }

        it "shows the ECT history section" do
          get admin_teacher_training_path(teacher)
          expect(response.body).to include("ECT history")
          expect(response.body).to include(ect_training_period.lead_provider_name)
        end
      end

      context "when the latest training period is provider-led" do
        let(:older_started_on) { 2.years.ago.to_date }
        let(:newer_started_on) { 1.year.ago.to_date }
        let!(:older_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: older_started_on, finished_on: older_started_on + 1.day)
          FactoryBot.create(:training_period, ect_at_school_period: ect_period, started_on: older_started_on, finished_on: older_started_on + 1.day)
        end
        let!(:newer_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: newer_started_on, finished_on: nil)
          FactoryBot.create(:training_period, ect_at_school_period: ect_period, started_on: newer_started_on, finished_on: nil)
        end

        it "shows the move partnership link once" do
          get admin_teacher_training_path(teacher)
          expect(response.body.scan("Move to a different partnership").count).to eq(1)
        end
      end

      context "when the latest training period is school-led" do
        let(:older_started_on) { 2.years.ago.to_date }
        let(:newer_started_on) { 1.year.ago.to_date }
        let!(:older_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: older_started_on, finished_on: older_started_on + 1.day)
          FactoryBot.create(:training_period, ect_at_school_period: ect_period, started_on: older_started_on, finished_on: older_started_on + 1.day)
        end
        let!(:newer_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: newer_started_on, finished_on: nil)
          FactoryBot.create(:training_period, :school_led, ect_at_school_period: ect_period, started_on: newer_started_on, finished_on: nil)
        end

        it "does not show the move partnership link" do
          get admin_teacher_training_path(teacher)
          expect(response.body).not_to include("Move to a different partnership")
        end
      end

      context "when the teacher has a mentor training period" do
        let(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor) }
        let(:teacher) { mentor_training_period.mentor_at_school_period.teacher }

        it "shows the mentor history section" do
          get admin_teacher_training_path(teacher)
          expect(response.body).to include("Mentor history")
          expect(response.body).to include(mentor_training_period.school_partnership.school.name)
        end
      end

      context "when the teacher has no training periods" do
        let(:teacher) { FactoryBot.create(:teacher) }

        it "shows the empty state message" do
          get admin_teacher_training_path(teacher)
          expect(response.body).to include("There is no training history recorded for this teacher")
        end
      end

      context "with multiple ECT training periods" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:older_started_on) { 2.years.ago.to_date }
        let(:newer_started_on) { 1.year.ago.to_date }
        let!(:older_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: older_started_on, finished_on: older_started_on + 1.year)
          FactoryBot.create(:training_period, ect_at_school_period: ect_period, started_on: older_started_on, finished_on: older_started_on + 1.year)
        end
        let!(:newer_training_period) do
          ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on: newer_started_on, finished_on: newer_started_on + 1.year)
          FactoryBot.create(:training_period, ect_at_school_period: ect_period, started_on: newer_started_on, finished_on: newer_started_on + 1.year)
        end

        it "orders the periods with the most recent first" do
          get admin_teacher_training_path(teacher)

          expect(response.body).to include(newer_started_on.to_fs(:govuk))
          expect(response.body).to include(older_started_on.to_fs(:govuk))
          expect(response.body.index(newer_started_on.to_fs(:govuk))).to be < body.index(older_started_on.to_fs(:govuk))
        end
      end
    end
  end
end
