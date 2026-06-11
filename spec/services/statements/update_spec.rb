describe Statements::Update do
  include ActiveJob::TestHelper

  subject { described_class.new(author:, statement:, params:) }

  let(:user) { FactoryBot.create(:user, name: "Christopher Biggins", email: "christopher.biggins@education.gov.uk") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:statement) { FactoryBot.create(:statement, :open) }
  let(:new_payment_date) { statement.payment_date + 1.day }
  let(:params) { { payment_date: new_payment_date } }

  context "when the update is valid" do
    before { allow(Events::Record).to receive(:record_statement_updated_event!).and_call_original }

    it "updates and records an event" do
      subject.call

      expect(statement.reload.payment_date).to eq(new_payment_date)
      expect(Events::Record).to have_received(:record_statement_updated_event!).with(
        author:, statement:, modifications: hash_including("payment_date")
      )
    end

    context "when updating to an output fee month" do
      let(:statement) { FactoryBot.create(:statement, :open, :service_fee, month: 2) }
      let(:params) { { month: 11 } }

      it "sets fee_type to output" do
        subject.call
        expect(statement.reload.fee_type).to eq("output")
      end
    end

    context "when updating to a service fee month" do
      let(:statement) { FactoryBot.create(:statement, :open, :output_fee, month: 11) }
      let(:params) { { month: 2 } }

      it "sets fee_type to service" do
        subject.call
        expect(statement.reload.fee_type).to eq("service")
      end
    end
  end

  context "when the update is invalid" do
    let(:params) { { month: 99 } }

    it "raises ActiveRecord::RecordInvalid and does not persist the change" do
      expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)
      expect(statement.reload.month).not_to eq(99)
    end
  end
end
