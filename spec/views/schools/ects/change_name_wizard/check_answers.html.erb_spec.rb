RSpec.describe "schools/ects/change_name_wizard/check_answers.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, trn: "1693012") }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
  let(:store) { FactoryBot.build(:session_repository, name: "Jane Smith") }
  let(:wizard) do
    FactoryBot.build(
      :change_ect_name_wizard,
      current_step: :check_answers,
      ect_at_school_period:,
      store:
    )
  end

  before do
    assign(:ect_at_school_period, ect_at_school_period)
    assign(:wizard, wizard)
  end

  it "displays a reminder of the TRN for the record being changed" do
    render

    expect(rendered).to have_css(
      ".govuk-inset-text",
      text: "This will change the name for the record with the teacher reference number (TRN) 1693012."
    )
  end
end
