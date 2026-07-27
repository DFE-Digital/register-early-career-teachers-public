RSpec.describe "schools/mentors/change_name_wizard/check_answers.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, trn: "1693012") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
  let(:store) { FactoryBot.build(:session_repository, name: "Jane Smith") }
  let(:wizard) do
    FactoryBot.build(
      :change_mentor_name_wizard,
      current_step: :check_answers,
      mentor_at_school_period:,
      store:
    )
  end

  before do
    assign(:mentor_at_school_period, mentor_at_school_period)
    assign(:wizard, wizard)
  end

  it "displays a reminder of the TRN for the record being changed" do
    render

    expect(rendered).to have_css(
      ".govuk-inset-text",
      text: "This will change the name for teacher reference number (TRN) 1693012."
    )
  end
end
