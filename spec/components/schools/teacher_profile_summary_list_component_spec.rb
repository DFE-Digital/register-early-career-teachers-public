require "rails_helper"

RSpec.describe Schools::TeacherProfileSummaryListComponent, type: :component do
  let(:teacher) { FactoryBot.create(:teacher, trn: '9876543', trs_first_name: 'Kakarot', trs_last_name: 'SSJ') }
  let(:teacher_2) { FactoryBot.create(:teacher, trn: '987654', trs_first_name: 'Naruto', trs_last_name: 'Ninetails') }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
  let(:mentor_2) { FactoryBot.create(:mentor_at_school_period, :active, teacher: teacher_2, started_on: 3.years.ago) }
  let(:ect) do
    FactoryBot.create(:ect_at_school_period, :active, teacher:, started_on: Date.new(2021, 9, 1),
                                                      email: 'foobarect@madeup.com', working_pattern: 'full_time')
  end

  let!(:ongoing_mentorship) do
    FactoryBot.create(:mentorship_period, :active, mentee: ect, mentor:, started_on: 3.years.ago, finished_on: 2.years.ago)
  end

  let!(:ongoing_mentorship_2) do
    FactoryBot.create(:mentorship_period, :active, mentee: ect, mentor: mentor_2, started_on: 2.years.ago)
  end

  before do
    render_inline(described_class.new(ect))
  end

  it "renders the summary list container" do
    expect(page).to have_selector(".govuk-summary-list")
  end

  it "renders the name row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Name")
    expect(page).to have_text('Kakarot SSJ')
  end

  it "renders the email row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Email address")
    expect(page).to have_text('foobarect@madeup.com')
  end

  it "renders the mentor row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Mentor")
    expect(page).to have_text('Naruto Ninetails')
  end

  it "renders the school start date row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "School start date")
    expect(page).to have_text('September 2021')
  end

  it "renders the working pattern row with correct value" do
    expect(page).to have_selector(".govuk-summary-list__row", text: "Working pattern")
    expect(page).to have_text('Full time')
  end
end
