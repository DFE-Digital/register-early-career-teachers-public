RSpec.describe "Admin::Teachers::TimelineController", type: :request do
  describe "GET /admin/teachers/:teacher_id/timeline" do
    subject(:timeline) do
      get admin_teacher_timeline_path(teacher_id)
      response
    end

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:teacher_id) { teacher.id }

    it { is_expected.to redirect_to(sign_in_path) }

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it { is_expected.to have_http_status(:unauthorized) }
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it { is_expected.to have_http_status(:success) }

      it "renders the teacher navigation" do
        expect(timeline.body).to include("x-govuk-secondary-navigation")
      end

      context "when there are events" do
        let!(:event) { FactoryBot.create(:event, teacher:) }

        it "renders the timeline" do
          expect(timeline.body).to include("app-timeline")
        end
      end

      context "when there are no events" do
        it "does not render the timeline" do
          expect(timeline.body).not_to include("app-timeline")
          expect(timeline.body).to include("No timeline of events for this teacher")
        end
      end

      context "when there is no matching teacher" do
        let(:teacher_id) { 123 }

        it { is_expected.to have_http_status(:not_found) }
      end
    end
  end
end
