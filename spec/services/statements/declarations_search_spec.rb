RSpec.describe Statements::DeclarationsSearch do
  subject(:statement_declarations) { described_class.new(statement:).declarations }

  around do |example|
    travel_to(Time.zone.local(2024, 11, 15, 12)) { example.run }
  end

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      lead_provider_delivery_partnership: FactoryBot.create(
        :lead_provider_delivery_partnership,
        active_lead_provider:
      )
    )
  end

  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      school_partnership:,
      started_on: Time.zone.local(2024, 10, 1)
    )
  end

  let(:base_declaration_date) { Time.zone.local(2025, 11, 10, 10) }
  let(:selected_declaration_ids) { [] }

  before do
    selection = instance_double(Statements::DeclarationSelection, selected_declaration_ids:)
    allow(Statements::DeclarationSelection).to receive(:new).with(statement:).and_return(selection)
  end

  context "when selecting declarations linked to a statement" do
    let(:statement) { FactoryBot.create(:statement, contract:, active_lead_provider:, month: 11, year: 2024) }
    let!(:payment_declaration) do
      FactoryBot.create(
        :declaration,
        :paid,
        training_period:,
        payment_statement: statement,
        declaration_date: base_declaration_date,
        created_at: base_declaration_date
      )
    end
    let!(:clawback_declaration) do
      FactoryBot.create(
        :declaration,
        :awaiting_clawback,
        training_period:,
        clawback_statement: statement,
        declaration_date: base_declaration_date + 2.days,
        created_at: base_declaration_date + 2.days
      )
    end
    let!(:unrelated_declaration) { FactoryBot.create(:declaration) }
    let(:selected_declaration_ids) { [payment_declaration.id, clawback_declaration.id] }

    it "returns declarations linked through payment or clawback statement" do
      expect(statement_declarations).to contain_exactly(payment_declaration, clawback_declaration)
    end
  end

  context "when ordering statement declarations" do
    let(:statement) { FactoryBot.create(:statement, contract:, active_lead_provider:, month: 12, year: 2024) }
    let!(:earlier_declaration) do
      earlier_training_period = FactoryBot.create(
        :training_period,
        :for_ect,
        :ongoing,
        school_partnership:,
        started_on: Time.zone.local(2024, 10, 1)
      )

      FactoryBot.create(
        :declaration,
        :paid,
        training_period: earlier_training_period,
        payment_statement: statement,
        declaration_date: base_declaration_date + 3.days,
        created_at: base_declaration_date + 3.days
      )
    end
    let!(:later_declaration) do
      later_training_period = FactoryBot.create(
        :training_period,
        :for_ect,
        :ongoing,
        school_partnership:,
        started_on: Time.zone.local(2024, 10, 1)
      )

      FactoryBot.create(
        :declaration,
        :paid,
        training_period: later_training_period,
        payment_statement: statement,
        declaration_date: base_declaration_date + 4.days,
        created_at: base_declaration_date + 4.days
      )
    end
    let(:selected_declaration_ids) { [later_declaration.id, earlier_declaration.id] }

    it "orders declarations chronologically" do
      expect(statement_declarations.to_a).to eq([earlier_declaration, later_declaration])
    end
  end
end
