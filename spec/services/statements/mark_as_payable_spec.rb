RSpec.describe Statements::MarkAsPayable do
  describe ".mark_all_eligible!" do
    it "marks open statements past their deadline" do
      statement = FactoryBot.create(:statement, :open, deadline_date: 1.day.ago, payment_date: Time.zone.now)
      eligible_declaration = FactoryBot.create(
        :declaration, :eligible,
        framework_agreement: statement.contract.framework_agreement,
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
      statement = FactoryBot.create(:statement, :payable, deadline_date: 1.day.ago, payment_date: Time.zone.now)

      expect { described_class.mark_all_eligible! }.not_to(change { statement.reload.status })
    end

    it "ignores statements that are already paid" do
      statement = FactoryBot.create(:statement, :paid, deadline_date: 1.day.ago, payment_date: Time.zone.now)

      expect { described_class.mark_all_eligible! }.not_to(change { statement.reload.status })
    end
  end

  describe ".check_forthcoming_statements!" do
    let(:framework_agreement) { FactoryBot.create(:framework_agreement) }

    let!(:past_statement) do
      FactoryBot.create(:statement, :paid, deadline_date: 1.month.ago, payment_date: 3.weeks.ago, framework_agreement:)
    end

    let!(:past_statement_but_open) do
      FactoryBot.create(:statement, :open, deadline_date: 1.day.ago, payment_date: Time.zone.now, framework_agreement:)
    end

    let!(:forthcoming_statement) do
      FactoryBot.create(:statement, :open, deadline_date: 1.month.from_now, payment_date: 6.weeks.from_now, framework_agreement:)
    end

    let!(:future_statement) do
      FactoryBot.create(:statement, :open, deadline_date: 2.months.from_now, payment_date: 10.weeks.from_now, framework_agreement:)
    end

    it "validates only the statements for the next deadline_date" do
      instance = instance_double(described_class)
      expect(instance).to receive(:check_for_errors!).once

      allow(described_class).to receive(:new).with(forthcoming_statement).and_return(instance)

      expect(described_class).not_to receive(:new).with(past_statement)
      expect(described_class).not_to receive(:new).with(past_statement_but_open)
      expect(described_class).not_to receive(:new).with(future_statement)

      described_class.check_forthcoming_statements!
    end
  end

  describe "#mark!" do
    subject { described_class.new(statement) }

    let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
    let(:statement) do
      FactoryBot.create(:statement, :open, deadline_date: 1.day.ago, payment_date: Time.zone.now, framework_agreement:)
    end

    %i[payable paid].each do |status|
      it "raises StatementNotOpenError when statement is #{status}" do
        statement = FactoryBot.create(
          :statement,
          status,
          deadline_date: 1.day.ago,
          payment_date: Time.zone.now,
          framework_agreement:
        )

        expect { described_class.new(statement).mark! }.to raise_error(
          Statements::StatementNotOpenError,
          "Cannot mark statement as payable: statement is #{status}"
        )
      end
    end

    it "transitions the statement from open to payable" do
      subject.mark!

      expect(statement.reload).to be_payable
    end

    it "transitions eligible declarations to payable" do
      declaration = FactoryBot.create(
        :declaration, :eligible,
        framework_agreement:,
        payment_statement: statement
      )

      subject.mark!

      expect(declaration.reload.payment_status).to eq("payable")
    end

    it "does not affect declarations in other payment states" do
      voided_declaration = FactoryBot.create(
        :declaration, :voided,
        framework_agreement:,
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
        framework_agreement:,
        payment_statement: statement
      )

      subject.mark!

      expect(Event.where(event_type: "teacher_declaration_payable").sole).to have_attributes(
        teacher_id: declaration.training_period.teacher.id,
        training_period_id: declaration.training_period.id,
        declaration_id: declaration.id
      )
    end

    it "records a statement marked payable event" do
      subject.mark!

      event = Event.where(event_type: "statement_marked_payable").sole
      expect(event).to have_attributes(
        statement_id: statement.id,
        framework_agreement_id: framework_agreement.id,
        lead_provider_id: framework_agreement.lead_provider_id
      )
      expect(event.metadata).to eq("contract_period_year" => framework_agreement.contract_period_year)
    end

    it "rolls back all changes if an error occurs" do
      declaration = FactoryBot.create(
        :declaration, :eligible,
        framework_agreement:,
        payment_statement: statement
      )

      allow(statement).to receive(:mark_as_payable!).and_raise(StandardError)

      expect { subject.mark! }.to raise_error(StandardError)
      expect(declaration.reload.payment_status).to eq("eligible")
      expect(statement.reload).to be_open
    end
  end

  describe "#check_for_errors!" do
    subject { described_class.new(statement) }

    let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
    let(:statement) do
      FactoryBot.create(:statement, :open, deadline_date: 1.day.from_now, payment_date: 2.days.from_now, framework_agreement:)
    end
    let(:declaration) { FactoryBot.create(:declaration, :eligible, framework_agreement:, payment_statement: statement) }

    %i[payable paid].each do |status|
      it "raises StatementNotOpenError when statement is #{status}" do
        statement = FactoryBot.create(
          :statement,
          status,
          deadline_date: 1.day.ago,
          payment_date: Time.zone.now,
          framework_agreement:
        )

        expect { described_class.new(statement).check_for_errors! }.to raise_error(
          Statements::StatementNotOpenError,
          "Cannot mark statement as payable: statement is #{status}"
        )
      end
    end

    it "does not modify the statement" do
      expect {
        subject.check_for_errors!
      }.not_to(change { statement })
    end

    it "validates payment declarations" do
      # because rubocop won't allow us to use allow/receive/return on the subject
      subject.instance_variable_set(:@eligible_declarations, [declaration])

      expect(declaration).to receive(:valid?).once
      subject.check_for_errors!
    end

    it "does not modify the declarations" do
      expect {
        subject.check_for_errors!
      }.not_to(change { declaration })
    end

    context "when a declaration is not valid" do
      before do
        allow(declaration).to receive(:valid?).and_return(false)
        declaration.errors.add(:mentorship_period, "Mentorship period must belong to the trainee")
        # because rubocop won't allow us to use allow/receive/return on the subject
        subject.instance_variable_set(:@eligible_declarations, [declaration])
      end

      it "records a Sentry message" do
        expect(Sentry).to receive(:capture_message)
          .with("[MarkAsPayable-Check] - Declaration [#{declaration.id}] invalid on statement [#{statement.id}]")
        subject.check_for_errors!
      end
    end
  end
end
