RSpec.describe "data_corrections:populate_declaration_void_events" do
  subject(:run_task) { Rake::Task["data_corrections:populate_declaration_void_events"].invoke }

  let(:user) { FactoryBot.create(:user, :finance) }
  let!(:voided_declaration_without_event) { FactoryBot.create(:declaration, :voided_by_user, voided_by_user: user) }
  let!(:clawed_back_declaration_without_event) { FactoryBot.create(:declaration, :voided_by_user, :clawed_back, voided_by_user: user) }
  let!(:declaration_with_event) { FactoryBot.create(:declaration, :voided_by_user, voided_by_user: user) }
  let!(:provider_voided_declaration) { FactoryBot.create(:declaration, :voided) }
  let!(:existing_event) do
    FactoryBot.create(
      :event,
      declaration: declaration_with_event,
      event_type: "teacher_declaration_voided",
      author_id: user.id,
      author_name: user.name,
      author_email: user.email,
      author_type: "dfe_staff_user"
    )
  end

  before do
    allow($stdout).to receive(:puts)
  end

  after do
    Rake::Task["data_corrections:populate_declaration_void_events"].reenable
  end

  it "backfills missing voided and awaiting clawback events" do
    expect { run_task }.to change(Event, :count).by(2)

    expect(voided_declaration_without_event.events.sole.event_type).to eq("teacher_declaration_voided")
    expect(clawed_back_declaration_without_event.events.sole.event_type).to eq("teacher_declaration_awaiting_clawback")
    expect(declaration_with_event.events.sole).to eq(existing_event)
    expect(provider_voided_declaration.events).to be_empty
  end

  it "reports the number of created and skipped events" do
    run_task

    expect($stdout).to have_received(:puts).with("Created: 2, skipped: 1")
  end

  it "skips existing events when run again" do
    run_task
    Rake::Task["data_corrections:populate_declaration_void_events"].reenable

    expect {
      Rake::Task["data_corrections:populate_declaration_void_events"].invoke
    }.not_to change(Event, :count)

    expect($stdout).to have_received(:puts).with("Created: 0, skipped: 3")
  end
end
