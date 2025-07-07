RSpec.describe "appropriate_bodies/teachers/record_passed_outcome/new.html.erb" do
  let(:teacher) { create(:teacher) }
  let(:appropriate_body) { build(:appropriate_body) }
  let(:pending_induction_submission) { PendingInductionSubmission.new }

  before do
    assign(:appropriate_body, appropriate_body)
    assign(:pending_induction_submission, pending_induction_submission)
    assign(:teacher, teacher)

    render
  end

  it 'renders a form with the expected fields' do
    expect(rendered).to have_css('form')
  end

  it 'has a date field for the leaving date' do
    expect(rendered).to have_css('legend', text: "When did they move from #{appropriate_body.name}?")
    expect(rendered).to have_css('form label', text: 'Day')
    expect(rendered).to have_css('form label', text: 'Month')
    expect(rendered).to have_css('form label', text: 'Year')
  end

  it 'has a date field for the extension length' do
    expect(rendered).to have_css('label', text: 'How many terms of induction did they spend with you?')
  end

  it 'has a warning submit button' do
    expect(rendered).to have_css('button.govuk-button')
  end
end
