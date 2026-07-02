RSpec.describe Statements::AuthorisePayment do
  subject { described_class.new(statement:, author:) }

  let(:user)      { FactoryBot.create(:user, :finance) }
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

      context "when there are declarations awaiting clawback" do
        let!(:declarations_awaiting_clawback) do
          FactoryBot.create_list(:declaration, 2, :with_ect,
                                 declaration_type: "started",
                                 clawback_status: "awaiting_clawback",
                                 school_partnership:,
                                 clawback_statement: statement)
        end

        it "marks declarations awaiting clawback as clawed back and records events" do
          expect(Events::Record).to receive(:record_teacher_declaration_clawed_back!).twice

          subject.authorise!

          expect(declarations.each(&:reload)).to all(be_paid)
          expect(declarations_awaiting_clawback.each(&:reload)).to all(be_clawed_back)
        end
      end
    end
  end
end
