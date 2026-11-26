RSpec.describe Schools::Mentors::ChangeNameWizard::Operations::UpdateName do
  subject(:operation) do
    described_class.new(repository: state_store.repository, step: wizard.current_step)
  end

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) do
    FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Smith")
  end
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }
  let(:state_store) do
    Schools::Mentors::ChangeNameWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      mentor_at_school_period:
    )
  end
  let(:wizard) do
    Schools::Mentors::ChangeNameWizard::Wizard.new(state_store:, current_step: :check_answers)
  end

  before do
    state_store.write(name: "Terry Pratchett")
    allow(wizard).to receive(:author).and_return(author)
  end

  it "executes successfully" do
    expect(operation.execute).to eq(success: true)
  end

  it "updates the mentor's corrected name" do
    expect { operation.execute }
      .to change { teacher.reload.corrected_name }
      .from(nil)
      .to("Terry Pratchett")
  end

  it "stores the original name in the state store" do
    operation.execute

    expect(state_store.old_name).to eq("Terry Smith")
  end

  it "records an event with the previous and new names" do
    freeze_time

    operation.execute

    event = Event.where(event_type: "teacher_name_updated_by_user").sole
    expect(event).to have_attributes(
      teacher_id: teacher.id,
      happened_at: Time.current
    )
    expect(event.heading).to include("Terry Smith", "Terry Pratchett")
  end
end
