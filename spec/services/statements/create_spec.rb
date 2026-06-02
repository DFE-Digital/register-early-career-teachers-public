describe Statements::Create do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, params:) }

  let(:user) { FactoryBot.create(:user, name: "Christopher Biggins", email: "christopher.biggins@education.gov.uk") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:) }

  let(:params) do
    {
      contract_id: contract.id,
      month: 11,
      year: contract_period.year,
      fee_type: "output",
      deadline_date: Date.new(contract_period.year, 11, 1),
      payment_date: Date.new(contract_period.year, 12, 25)
    }
  end

  context "when the statement is valid" do
    before { allow(Events::Record).to receive(:record_statement_created_event!).and_call_original }

    it "creates and records an event" do
      statement = subject.call

      expect(statement).to be_a(Statement)
      expect(statement).to be_persisted
      expect(statement.contract).to eq(contract)
      expect(statement).to be_status_open
      expect(Events::Record).to have_received(:record_statement_created_event!).with(author:, statement:)
    end
  end

  context "when the statement is invalid" do
    let(:params) { super().merge(month: 99) }

    it "raises ActiveRecord::RecordInvalid and does not create a statement" do
      expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Statement.count).to eq(0)
    end
  end
end
