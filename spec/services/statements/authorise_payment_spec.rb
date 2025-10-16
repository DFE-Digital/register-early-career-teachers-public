RSpec.describe Statements::AuthorisePayment do
  subject { described_class.new(statement, author:) }

  let(:statement) { FactoryBot.create(:statement, :payable, marked_as_paid_at: nil) }
  let(:user) { FactoryBot.create(:user, email: "test@example.com", name: "Test User") }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  describe "#authorise!" do
    context "can authorise payment" do
      before { allow(statement).to receive(:can_authorise_payment?).and_return(true) }

      it "sets marked_as_paid_at and status to paid and records the event with the same timestamp" do
        freeze_time do
          expect(Events::Record).to receive(:record_statement_authorised_for_payment_event!).with(
            author:,
            statement:,
            happened_at: kind_of(ActiveSupport::TimeWithZone)
          )

          expect(subject.authorise!).to be(true)
        end

        statement.reload
        expect(statement.marked_as_paid_at).to be_present
        expect(statement).to be_paid
      end

      it "uses marked_as_paid_at as happened_at" do
        freeze_time do
          allow(Events::Record).to receive(:record_statement_authorised_for_payment_event!)

          expect(subject.authorise!).to be(true)

          expect(Events::Record).to have_received(:record_statement_authorised_for_payment_event!).with(
            hash_including(happened_at: statement.reload.marked_as_paid_at)
          )
        end
      end
    end

    context "cannot authorise payment" do
      before { allow(statement).to receive(:can_authorise_payment?).and_return(false) }

      it "raises NotAuthorisable and does not record an event" do
        expect(Events::Record).not_to receive(:record_statement_authorised_for_payment_event!)

        expect {
          subject.authorise!
        }.to raise_error(Statements::AuthorisePayment::NotAuthorisable)
      end
    end

    context "when mark_as_paid! raises" do
      before do
        allow(statement).to receive(:can_authorise_payment?).and_return(true)
        allow(statement).to receive(:mark_as_paid!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises, does not record an event, and does not persist changes" do
        expect(Events::Record).not_to receive(:record_statement_authorised_for_payment_event!)

        expect {
          subject.authorise!
        }.to raise_error(ActiveRecord::RecordInvalid)

        statement.reload
        expect(statement.marked_as_paid_at).to be_nil
        expect(statement).not_to be_paid
      end
    end

    context "when recording the event raises" do
      before do
        allow(statement).to receive(:can_authorise_payment?).and_return(true)
        allow(Events::Record).to receive(:record_statement_authorised_for_payment_event!)
          .and_raise(StandardError)
      end

      it "raises and rolls back the payment change" do
        expect {
          subject.authorise!
        }.to raise_error(StandardError)

        statement.reload
        expect(statement.marked_as_paid_at).to be_nil
        expect(statement).not_to be_paid
      end
    end
  end
end
