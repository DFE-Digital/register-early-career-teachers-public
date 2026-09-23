describe Statements::Destroy do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, statement:) }

  let(:user) { FactoryBot.create(:user, name: "Christopher Biggins", email: "christopher.biggins@education.gov.uk") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:statement) { FactoryBot.create(:statement, :open) }

  context "when the statement has no declarations" do
    it "destroys the statement and its adjustments and records an event" do
      adjustment = FactoryBot.create(:statement_adjustment, statement:)
      framework_agreement = statement.framework_agreement

      subject.call

      expect(Statement.exists?(statement.id)).to be(false)
      expect(Statement::Adjustment.exists?(adjustment.id)).to be(false)

      event = Event.where(event_type: "statement_deleted").sole
      expect(event).to have_attributes(
        framework_agreement_id: framework_agreement.id,
        lead_provider_id: framework_agreement.lead_provider_id
      )
      expect(event.modifications).to be_present
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
