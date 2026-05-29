RSpec.describe Statements::AuthorisePayment do
  subject { described_class.new(statement:, author:) }

  let(:user)      { FactoryBot.create(:user, email: "test@example.com", name: "Test User") }
  let(:author)    { Sessions::Users::DfEPersona.new(email: user.email) }

  let!(:statement) { FactoryBot.create(:statement, :payable, deadline_date: Date.yesterday) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: statement.contract_period.year, active_lead_provider: statement.active_lead_provider) }

  describe "#authorise!" do
    context "when the statement is not payable" do
      let(:statement) { FactoryBot.create(:statement) }

      it "raises NotAuthorisable" do
        expect {
          subject.authorise!
        }.to raise_error(Statements::AuthorisePayment::NotAuthorisable)
      end
    end

    context "when the statement is payable" do
      let!(:declarations) do
        FactoryBot.create_list(:declaration, 3, :with_ect,
                               declaration_type: "started",
                               payment_status: "payable",
                               school_partnership:,
                               payment_statement: statement)
      end

      it "marks all payable declarations as paid and records events" do
        expect(Events::Record).to receive(:record_teacher_declaration_paid!).exactly(3).times

        subject.authorise!

        expect(declarations.each(&:reload)).to all(be_paid)
      end

      it "marks the statement as paid" do
        freeze_time do
          subject.authorise!

          expect(statement.reload).to be_paid
          expect(statement.marked_as_paid_at).to eq(Time.zone.now)
        end
      end

      it "records a statement authorised for payment event" do
        expect(Events::Record).to receive(:record_statement_authorised_for_payment_event!).with(
          statement:,
          author:
        )

        subject.authorise!
      end

      context "when the statement errors when transitioning to paid" do
        before do
          allow(statement).to receive(:mark_as_paid!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "raises, does not create events and does not update the statement or declarations" do
          expect {
            subject.authorise!
          }.to raise_error(ActiveRecord::RecordInvalid)

          expect(Event.count).to eq(0)

          expect(statement.reload.marked_as_paid_at).to be_nil
          expect(statement).not_to be_paid
          expect(declarations.each(&:reload)).to all(be_payable)
        end
      end

      context "when a payment declaration cannot transition to paid" do
        before do
          allow(subject).to receive(:declarations_payable)
            .and_return(declarations)

          allow(declarations.first).to receive(:mark_as_paid!).and_call_original
          allow(declarations.second).to receive(:mark_as_paid!).and_raise(StandardError)

          call_count = 0

          allow_any_instance_of(Declaration)
            .to receive(:mark_as_paid!) do
              call_count += 1
              raise StandardError if call_count == 2
            end
        end

        it "raises, does not record events, and does not persist changes" do
          expect {
            subject.authorise!
          }.to raise_error(StandardError)

          expect(Event.count).to eq(0)

          expect(statement.reload.marked_as_paid_at).to be_nil
          expect(statement).not_to be_paid
          expect(declarations.each(&:reload)).to all(be_payable)
        end
      end

      context "when there are declarations awaiting clawback" do
        let!(:declarations_awaiting_clawback) do
          FactoryBot.create_list(:declaration, 2, :with_ect,
                                 declaration_type: "started",
                                 clawback_status: "awaiting_clawback",
                                 school_partnership:,
                                 payment_statement: statement)
        end

        it "marks declarations awaiting clawback as clawed back and records events" do
          expect(Events::Record).to receive(:record_teacher_declaration_clawed_back!).twice

          subject.authorise!

          expect(declarations.each(&:reload)).to all(be_paid)
          expect(declarations_awaiting_clawback.each(&:reload)).to all(be_clawed_back)
        end

        context "when a clawback declaration cannot transition to paid" do
          before do
            allow(subject).to receive(:declarations_awaiting_clawback)
              .and_return(declarations_awaiting_clawback)

            allow(declarations_awaiting_clawback.first).to receive(:mark_as_paid!).and_call_original
            allow(declarations_awaiting_clawback.second).to receive(:mark_as_paid!).and_raise(StandardError)
          end

          it "raises, does not record an event, and does not persist changes" do
            expect {
              subject.authorise!
            }.to raise_error(StandardError)

            expect(Event.count).to eq(0)

            expect(statement.reload.marked_as_paid_at).to be_nil
            expect(statement).not_to be_paid
            expect(declarations.each(&:reload)).to all(be_payable)
            expect(declarations_awaiting_clawback.each(&:reload)).to all(be_awaiting_clawback)
          end
        end
      end
    end
  end
end
