describe Statements::Destroy do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, statement:) }

  let(:user) { FactoryBot.create(:user, name: "Christopher Biggins", email: "christopher.biggins@education.gov.uk") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:statement) { FactoryBot.create(:statement, :open) }

  context "when the statement has no declarations" do
    before { allow(Events::Record).to receive(:record_statement_deleted_event!).and_call_original }

    it "destroys the statement and its adjustments and records an event" do
      adjustment = FactoryBot.create(:statement_adjustment, statement:)

      subject.call

      expect(Statement.exists?(statement.id)).to be(false)
      expect(Statement::Adjustment.exists?(adjustment.id)).to be(false)
      expect(Events::Record).to have_received(:record_statement_deleted_event!).with(
        hash_including(author:, active_lead_provider: an_instance_of(ActiveLeadProvider))
      )
    end
  end

  context "when the statement has declarations" do
    let(:declaration) { FactoryBot.create(:declaration, :eligible) }
    let(:statement) { declaration.payment_statement }

    it "raises DeletionError and keeps the statement" do
      expect { subject.call }.to raise_error(Statements::Destroy::DeletionError, "Cannot delete a statement with declarations")
      expect(Statement.exists?(statement.id)).to be(true)
    end
  end
end
