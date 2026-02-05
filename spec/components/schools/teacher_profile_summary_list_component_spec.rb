RSpec.describe Schools::TeacherProfileSummaryListComponent, type: :component do
  subject { page }

  let(:school) { FactoryBot.create(:school) }
  let(:mentee_teacher) { FactoryBot.create(:teacher, trn: "9876543", trs_first_name: "Kakarot", trs_last_name: "SSJ") }
  let(:mentor_teacher) { FactoryBot.create(:teacher, trn: "987654", trs_first_name: "Naruto", trs_last_name: "Ninetails") }
  let(:previous_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: 3.years.ago) }
  let(:current_mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: mentor_teacher, started_on: 3.years.ago) }
  let(:mentee) do
    FactoryBot.create(:ect_at_school_period, :ongoing, school:, teacher: mentee_teacher, started_on: Date.new(2021, 9, 1),
                                                       email: "foobarect@madeup.com", working_pattern: "full_time")
  end

  before do
    FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: previous_mentor, started_on: 3.years.ago, finished_on: 2.years.ago)
    FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor: current_mentor, started_on: 2.years.ago)

    # rubocop:disable RSpec/AnyInstance (ECTHelper is a module)
    allow_any_instance_of(ECTHelper).to receive(:ect_mentor_details).with(mentee).and_return("ECTHelper#ect_mentor_details")
    allow_any_instance_of(ECTHelper).to receive(:ect_status).with(mentee, current_school: school).and_return("ECTHelper#ect_status")
    # rubocop:enable RSpec/AnyInstance

    render_inline(described_class.new(mentee, current_school: school))
  end

  it "renders the summary list container" do
    expect(page).to have_selector(".govuk-summary-list")
  end

  it { is_expected.to have_selector(".govuk-summary-list__row", count: 6) }
  it { is_expected.to have_summary_list_row("Name", value: "Kakarot SSJ") }
  it { is_expected.to have_summary_list_row("Email address", value: "foobarect@madeup.com") }
  it { is_expected.to have_summary_list_row("Mentor", value: "ECTHelper#ect_mentor_details") }
  it { is_expected.to have_summary_list_row("School start date", value: "1 September 2021") }
  it { is_expected.to have_summary_list_row("Working pattern", value: "Full time") }
  it { is_expected.to have_summary_list_row("Status") }
  it { is_expected.to have_text("ECTHelper#ect_status") }
end
