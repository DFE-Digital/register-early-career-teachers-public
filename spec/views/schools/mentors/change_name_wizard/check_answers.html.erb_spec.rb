RSpec.describe "schools/mentors/change_name_wizard/check_answers.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, trn: "1693012") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
  let(:school) { mentor_at_school_period.school }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(
      current_step: :check_answers,
      state_store:
    )
  end

  before do
    state_store.write(name: "Jane Smith")
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
