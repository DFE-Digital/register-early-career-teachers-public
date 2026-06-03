RSpec.describe Backfill::RecordDeclarationEvent do
  subject(:process) do
    described_class.new(
      declaration:,
      status:,
      statement:
    ).process
  end

  # Silence puts statements
  before do
    allow($stdout).to receive(:puts)
  end

  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year:, active_lead_provider:) }
  let(:active_lead_provider) { statement.active_lead_provider }
  let(:contract) { statement.contract }
  let(:year) { statement.contract_period.year }

  let(:statement) { FactoryBot.create(:statement, :paid) }

  let(:status) { :paid }

  let!(:declaration) do
    FactoryBot.create(
      :declaration,
      :with_ect,
      payment_status: "paid",
      school_partnership:,
      payment_statement: statement
    )
  end

  describe "#process" do
    context "when the event does not already exist" do
      it "creates the declaration event" do
        expect { process }
          .to change(Event, :count).by(1)

        event = Event.last

        expect(event.event_type).to eq("teacher_declaration_paid")
        expect(event.declaration).to eq(declaration)
        expect(event.teacher).to eq(declaration.teacher)
        expect(event.training_period).to eq(declaration.training_period)
        expect(event.happened_at).to eq(statement.payment_date.in_time_zone)

        expect(event.author_name).to eq("System")
        expect(event.author_type).to eq("system")
      end

      it { is_expected.to be_truthy }
    end

    context "when the event already exists" do
      before do
        FactoryBot.create(
          :event,
          event_type: "teacher_declaration_paid",
          declaration:
        )
      end

      it "does not create another event" do
        expect { process }
          .not_to change(Event, :count)
      end

      it { is_expected.to be_falsy }
    end

    context "when the statement is not paid" do
      let(:statement) { FactoryBot.create(:statement) }

      it "does not create the event" do
        expect { process }
          .not_to change(Event, :count)
      end

      it { is_expected.to be_falsy }
    end

    context "when the declaration is a clawback declaration" do
      let!(:declaration) do
        FactoryBot.create(
          :declaration,
          :with_ect,
          payment_status: "paid",
          clawback_status: "clawed_back",
          school_partnership:,
          payment_statement: statement
        )
      end

      let(:status) { :clawed_back }

      it "creates a clawed back event" do
        process

        expect(Event.last.event_type)
          .to eq("teacher_declaration_clawed_back")
      end

      it { is_expected.to be_truthy }
    end

    context "with an invalid status" do
      let(:status) { :foo }

      it "raises an error" do
        expect { process }
          .to raise_error(
            ArgumentError,
            "Unknown declaration event status: :foo"
          )
      end
    end
  end
end
