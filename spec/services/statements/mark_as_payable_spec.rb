RSpec.describe Statements::MarkAsPayable do
  describe ".mark_all_eligible!" do
    it "marks open statements past their deadline" do
      statement = FactoryBot.create(:statement, :open, deadline_date: 1.day.ago)
      eligible_declaration = FactoryBot.create(
        :declaration, :eligible,
        active_lead_provider: statement.contract.active_lead_provider,
        payment_statement: statement
      )

      described_class.mark_all_eligible!

      expect(statement.reload).to be_payable
      expect(eligible_declaration.reload.payment_status).to eq("payable")
    end

    it "ignores statements with a future deadline" do
      statement = FactoryBot.create(:statement, :open, deadline_date: 1.day.from_now)

      described_class.mark_all_eligible!

      expect(statement.reload).to be_open
    end

    it "ignores statements with a deadline of today" do
      statement = FactoryBot.create(:statement, :open, deadline_date: Date.current)

      described_class.mark_all_eligible!

      expect(statement.reload).to be_open
    end

    it "ignores statements that are already payable" do
      statement = FactoryBot.create(:statement, :payable, deadline_date: 1.day.ago)

      expect { described_class.mark_all_eligible! }.not_to(change { statement.reload.status })
    end

    it "ignores statements that are already paid" do
      statement = FactoryBot.create(:statement, :paid, deadline_date: 1.day.ago)

      expect { described_class.mark_all_eligible! }.not_to(change { statement.reload.status })
    end
  end

  describe "#mark!" do
    subject { described_class.new(statement) }

    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:statement) { FactoryBot.create(:statement, :open, deadline_date: 1.day.ago, active_lead_provider:) }

    it "transitions the statement from open to payable" do
      subject.mark!

      expect(statement.reload).to be_payable
    end

    it "transitions eligible declarations to payable" do
      declaration = FactoryBot.create(
        :declaration, :eligible,
        active_lead_provider:,
        payment_statement: statement
      )

      subject.mark!

      expect(declaration.reload.payment_status).to eq("payable")
    end

    it "does not affect declarations in other payment states" do
      voided_declaration = FactoryBot.create(
        :declaration, :voided,
        active_lead_provider:,
        payment_statement: statement
      )
      no_payment_declaration = FactoryBot.create(:declaration, :no_payment)

      subject.mark!

      expect(voided_declaration.reload.payment_status).to eq("voided")
      expect(no_payment_declaration.reload.payment_status).to eq("no_payment")
    end

    it "records a declaration marked payable event for each eligible declaration" do
      declaration = FactoryBot.create(
        :declaration, :eligible,
        active_lead_provider:,
        payment_statement: statement
      )

      expect(Events::Record).to receive(:record_teacher_declaration_marked_payable!).with(
        author: instance_of(Events::SystemAuthor),
        teacher: declaration.training_period.teacher,
        training_period: declaration.training_period,
        declaration:
      )

      subject.mark!
    end

    it "records a statement marked payable event" do
      expect(Events::Record).to receive(:record_statement_marked_payable!).with(
        author: instance_of(Events::SystemAuthor),
        statement:
      )

      subject.mark!
    end

    it "rolls back all changes if an error occurs" do
      declaration = FactoryBot.create(
        :declaration, :eligible,
        active_lead_provider:,
        payment_statement: statement
      )

      allow(statement).to receive(:mark_as_payable!).and_raise(StandardError)

      expect { subject.mark! }.to raise_error(StandardError)
      expect(declaration.reload.payment_status).to eq("eligible")
      expect(statement.reload).to be_open
    end
  end
end
