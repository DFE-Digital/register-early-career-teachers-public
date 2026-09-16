RSpec.describe Statements::AuthorisePayment do
  subject { described_class.new(statement:, author:) }

  let(:user)      { FactoryBot.create(:user, :finance) }
  let(:author)    { Sessions::Users::DfEPersona.new(email: user.email) }

  let!(:statement) { FactoryBot.create(:statement, :payable, deadline_date: Date.yesterday) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: statement.contract_period.year, framework_agreement: statement.framework_agreement) }

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
        subject.authorise!

        expect(declarations.each(&:reload)).to all(be_paid)

        events = Event.where(event_type: "teacher_declaration_paid")
        expect(events.count).to eq(3)
        expect(events.map(&:declaration_id)).to match_array(declarations.map(&:id))
      end

      it "marks the statement as paid" do
        freeze_time do
          subject.authorise!

          expect(statement.reload).to be_paid
          expect(statement.marked_as_paid_at).to eq(Time.zone.now)
        end
      end

      it "records a statement authorised for payment event" do
        subject.authorise!

        event = Event.where(event_type: "statement_authorised_for_payment").sole
        expect(event).to have_attributes(
          statement_id: statement.id,
          framework_agreement_id: statement.framework_agreement.id,
          lead_provider_id: statement.lead_provider.id
        )
        expect(event.metadata).to eq("contract_period_year" => statement.framework_agreement.contract_period_year)
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
          subject.authorise!

          expect(declarations.each(&:reload)).to all(be_paid)
          expect(declarations_awaiting_clawback.each(&:reload)).to all(be_clawed_back)

          events = Event.where(event_type: "teacher_declaration_clawed_back")
          expect(events.count).to eq(2)
          expect(events.map(&:declaration_id)).to match_array(declarations_awaiting_clawback.map(&:id))
        end
      end
    end
  end
end
