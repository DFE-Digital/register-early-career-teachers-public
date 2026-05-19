RSpec.describe Backfill::RecordStatementPaymentEvents do
  subject { described_class.new(statement).process }

  let(:school_partnership) { FactoryBot.create(:school_partnership, :with_active_lead_provider, :for_year, year:) }
  let(:active_lead_provider) { school_partnership.active_lead_provider }
  let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

  let!(:payment_statement) do
    FactoryBot.create(:statement,
                      :adjustable,
                      :paid,
                      month: 8,
                      year:,
                      deadline_date: Date.new(year, 7, 31),
                      payment_date: Date.new(year, 8, 31),
                      active_lead_provider:,
                      contract:)
  end

  let!(:statement) do
    FactoryBot.create(:statement,
                      :adjustable,
                      :paid,
                      month: 9,
                      year:,
                      deadline_date: Date.new(year, 8, 31),
                      payment_date: Date.new(year, 9, 30),
                      active_lead_provider:,
                      contract:)
  end

  let(:uplift_count) { 0 }
  let(:year) { 2024 }
  let(:milestones) { %w[started retained-1 retained-2 retained-3 retained-4 extended-1 extended-2 extended-3 completed] }
  let(:paid_declarations) { [] }
  let(:clawed_back_declarations) { [] }
  let(:voided_declarations) { [] }

  before do
    allow($stdout).to receive(:puts)

    milestones.each do |declaration_type|
      pupil_premium_uplift = assign_uplift(declaration_type, uplift_count)

      paid_declarations << FactoryBot.create_list(:declaration, 2, :with_ect,
                                                  declaration_type:,
                                                  payment_status: "paid",
                                                  school_partnership:,
                                                  pupil_premium_uplift:,
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
                                                         payment_statement:,
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
                                                    payment_statement:,
                                                    clawback_statement: statement)
    end

    paid_declarations.flatten!
    clawed_back_declarations.flatten!
    voided_declarations.flatten!
  end

  describe "#process" do
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

    it "returns counts of created declaration events by type" do
      result = subject

      expect(result).to include(
        started: 3,
        retained: 8,
        extended: 6,
        completed: 3,
        clawed_back: 20
      )
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

  def assign_uplift(declaration_type, uplift_count)
    return false unless declaration_type == "started"

    uplift = uplift_count < 2 ? true : [true, false].sample
    uplift_count + 1 if uplift
    uplift
  end
end
