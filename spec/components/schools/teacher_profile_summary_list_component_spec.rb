require "rails_helper"

RSpec.describe Schools::TeacherProfileSummaryListComponent, type: :component do
  include TeacherHelper
  include ECTHelper

  let(:ect) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
  let!(:ongoing_mentorship) { FactoryBot.create(:mentorship_period, :active, mentee: ect, mentor:) }

  before do
    render_inline(described_class.new(ect))
  end

  it "renders the summary list container" do
    expect(page).to have_selector(".govuk-summary-list")
  end

  it "renders the name row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Name")
    expect(page).to have_text(teacher_full_name(ect.teacher))
  end

  it "renders the email row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Email address")
    expect(page).to have_text(ect.email)
  end

  it "renders the mentor row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Mentor")
    expect(page).to have_text(ect_mentor_details(ect))
  end

  it "renders the school start date row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "School start date")
    expect(page).to have_text(ect_start_date(ect))
  end

  it "renders the working pattern row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Working pattern")
    expect(page).to have_text(ect.working_pattern&.humanize)
  end
end
