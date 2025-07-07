RSpec.describe Schools::TeacherProfileSummaryListComponent, type: :component do
  let(:mentee_teacher) { create(:teacher, trn: '9876543', trs_first_name: 'Kakarot', trs_last_name: 'SSJ') }
  let(:mentor_teacher) { create(:teacher, trn: '987654', trs_first_name: 'Naruto', trs_last_name: 'Ninetails') }
  let(:previous_mentor) { create(:mentor_at_school_period, :active, started_on: 3.years.ago) }
  let(:current_mentor) { create(:mentor_at_school_period, :active, teacher: mentor_teacher, started_on: 3.years.ago) }
  let(:mentee) do
    create(:ect_at_school_period, :active, teacher: mentee_teacher, started_on: Date.new(2021, 9, 1),
                                           email: 'foobarect@madeup.com', working_pattern: 'full_time')
  end

  before do
    create(:mentorship_period, :active, mentee:, mentor: previous_mentor, started_on: 3.years.ago, finished_on: 2.years.ago)
    create(:mentorship_period, :active, mentee:, mentor: current_mentor, started_on: 2.years.ago)
    render_inline(described_class.new(mentee))
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

  describe '#rows' do
    it 'returns the correct number of rows' do
      expect(described_class.new(mentee).rows.count).to eq(5)
    end
  end
end
