RSpec.describe "schools/mentors/change_name_wizard/edit.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Smith") }
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
      current_step: :edit,
      state_store:
    )
  end

  before do
    assign(:mentor_at_school_period, mentor_at_school_period)
    assign(:wizard, wizard)
  end

  it "prefills the name and submits it under the edit step" do
    render

    expect(rendered).to have_css('input[name="edit[name]"][value="Terry Smith"]')
  end
end
