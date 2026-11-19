RSpec.describe Schools::Mentors::ChangeEmailAddressWizard::Operations::UpdateEmail do
  subject(:operation) { described_class.new(repository: state_store.repository, step: wizard.current_step) }

  let(:wizard) do
    Schools::Mentors::ChangeEmailAddressWizard::Wizard.new(state_store:, current_step: :check_answers)
  end
  let(:state_store) do
    Schools::Mentors::ChangeEmailAddressWizard::StateStore.new(
      repository: DfE::Wizard::Repository::InMemory.new,
      author:,
      mentor_at_school_period:
    )
  end
  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, school:, email: "old@example.com")
  end

  before do
    state_store.write(email: "new@example.com")
  end

  it "succeeds" do
    expect(operation.execute).to eq(success: true)
  end

  it "updates the mentor's email" do
    expect { operation.execute }
      .to change { mentor_at_school_period.reload.email }
      .from("old@example.com")
      .to("new@example.com")
  end

  it "stores the original email in the state store" do
    operation.execute
    expect(state_store.original_email).to eq("old@example.com")
  end

  it "records an event with the previous and new email addresses" do
    freeze_time

    operation.execute

    event = Event.where(event_type: "teacher_email_address_updated").sole
    expect(event).to have_attributes(
      mentor_at_school_period_id: mentor_at_school_period.id,
      school_id: school.id,
      teacher_id: mentor_at_school_period.teacher_id,
      happened_at: Time.current
    )
    expect(event.heading).to include("old@example.com", "new@example.com")
  end
end
