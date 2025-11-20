RSpec.describe Admin::Teachers::OverviewSummaryComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(teacher: presenter)) }

  let(:presenter) { Admin::TeacherPresenter.new(teacher) }
  let(:school) { FactoryBot.create(:school) }

  context "when the teacher is an Early Career Teacher" do
    let(:teacher) { FactoryBot.create(:teacher, corrected_name: "New Name", api_id: SecureRandom.uuid, trs_induction_status: "InProgress") }

    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:)
      FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:, email: "teacher@example.com")
    end

    it "renders the core summary rows" do
      expect(rendered).to have_text("Name")
      expect(rendered).to have_text("TRN")
      expect(rendered).to have_text("Role")
    end

    it "shows the TRS hint when the corrected name differs" do
      expect(rendered).to have_text("Name from TRS:")
    end

    it "includes the most recent email address for the teacher" do
      expect(rendered).to have_text("teacher@example.com")
    end

    it "links the current school to the admin overview page" do
      expect(rendered).to have_link(school.name, href: Rails.application.routes.url_helpers.admin_school_overview_path(school.urn))
    end

    it "displays the induction status for an ECT" do
      expect(rendered).to have_text("Induction status")
      expect(rendered).to have_text("In progress")
    end

    it "shows the API participant ID in a code block" do
      expect(rendered.css("code.app-code").text).to eq(teacher.api_id)
    end
  end

  context "when the teacher is not an Early Career Teacher" do
    let(:teacher) { FactoryBot.create(:teacher, api_id: SecureRandom.uuid, trs_induction_status: nil) }

    before do
      FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, email: "mentor@example.com")
    end

    it "does not render the induction status row" do
      expect(rendered).not_to have_text("Induction status")
    end
  end
end
