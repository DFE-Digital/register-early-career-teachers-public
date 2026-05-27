RSpec.describe Backfill::RecordStatementPaymentEvents do
  subject { described_class.new(statement).process }

  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year:, active_lead_provider:) }
  let(:active_lead_provider) { statement.active_lead_provider }
  let(:contract) { statement.contract }
  let(:year) { statement.contract_period.year }

  let!(:statement) { FactoryBot.create(:statement, :paid) }

  let(:milestones) { %w[started retained-1 retained-2 extended-1 completed] }
  let(:paid_declarations) { [] }
  let(:clawed_back_declarations) { [] }
  let(:voided_declarations) { [] }

  before do
    allow($stdout).to receive(:puts)

    previous_statement = FactoryBot.create(:statement, :paid, active_lead_provider:, contract:)

    milestones.each do |declaration_type|
      paid_declarations << FactoryBot.create_list(:declaration, 2, :with_ect,
                                                  declaration_type:,
                                                  payment_status: "paid",
                                                  school_partnership:,
                                                  payment_statement: statement)

      voided_declarations << FactoryBot.create(:declaration, :with_ect,
                                               declaration_type:,
                                               payment_status: "voided",
                                               school_partnership:,
                                               payment_statement: statement)

      clawed_back_declarations << FactoryBot.create_list(:declaration, 2, :with_ect,
                                                         declaration_type:,
                                                         payment_status: "paid",
                                                         clawback_status: "clawed_back",
                                                         school_partnership:,
                                                         payment_statement: previous_statement,
                                                         clawback_statement: statement)

      next unless %w[started completed].include?(declaration_type)

      paid_declarations << FactoryBot.create(:declaration, :with_mentor,
                                             declaration_type:,
                                             payment_status: "paid",
                                             school_partnership:,
                                             payment_statement: statement)

      clawed_back_declarations << FactoryBot.create(:declaration, :with_mentor,
                                                    declaration_type:,
                                                    payment_status: "paid",
                                                    clawback_status: "clawed_back",
                                                    school_partnership:,
                                                    payment_statement: previous_statement,
                                                    clawback_statement: statement)
    end

    paid_declarations.flatten!
    clawed_back_declarations.flatten!
    voided_declarations.flatten!
  end

  describe "#process" do
    it "returns counts of created declaration events by type" do
      result = subject

      expect(result).to include(
        started: 3,
        retained: 4,
        extended: 2,
        completed: 3,
        clawed_back: 12
      )
    end

    it "records paid events for each paid declaration on the statement" do
      allow(Backfill::RecordDeclarationEvent).to receive(:new).and_call_original

      subject

      paid_declarations.each do |declaration|
        expect(Backfill::RecordDeclarationEvent).to have_received(:new).with(
          declaration:,
          statement:,
          status: :paid
        )
      end
    end

    it "records clawed back events for clawed back declarations on the statement" do
      allow(Backfill::RecordDeclarationEvent).to receive(:new).and_call_original

      subject

      clawed_back_declarations.each do |declaration|
        expect(Backfill::RecordDeclarationEvent).to have_received(:new).with(
          declaration:,
          statement:,
          status: :clawed_back
        )
      end
    end

    it "does not record paid events for voided declarations on the statement" do
      allow(Backfill::RecordDeclarationEvent).to receive(:new).and_call_original

      subject

      voided_declarations.each do |declaration|
        expect(Backfill::RecordDeclarationEvent).not_to have_received(:new).with(
          declaration:,
          statement: anything,
          status: anything
        )
      end
    end

    it "creates a statement authorised for payment event" do
      expect { subject }
        .to change(
          Event.where(event_type: "statement_authorised_for_payment"),
          :count
        ).by(1)

      event = Event.find_by!(
        event_type: "statement_authorised_for_payment",
        statement:
      )

      expect(event.happened_at).to eq(statement.payment_date.in_time_zone)
      expect(event.lead_provider).to eq(active_lead_provider.lead_provider)
      expect(event.active_lead_provider).to eq(active_lead_provider)
      expect(event.author_name).to eq("System")
      expect(event.author_type).to eq("system")

      expect(event.metadata)
        .to include(
          "contract_period_year" => active_lead_provider.contract_period_year
        )
    end

    context "when a statement authorised for payment event already exists for the statement" do
      it "does not create a duplicate statement authorised event" do
        FactoryBot.create(
          :event,
          event_type: "statement_authorised_for_payment",
          statement:
        )

        expect { subject }
          .not_to change(
            Event.where(event_type: "statement_authorised_for_payment"),
            :count
          )
      end
    end
  end
end
