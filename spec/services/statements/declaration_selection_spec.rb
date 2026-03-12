RSpec.describe Statements::DeclarationSelection do
  subject(:selected_declaration_ids) { described_class.new(statement:).selected_declaration_ids }

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

  let(:band_max) { 10 }
  let(:banded_fee_structure) do
    FactoryBot.create(
      :contract_banded_fee_structure,
      recruitment_target: 10,
      uplift_fee_per_declaration: 0,
      monthly_service_fee: 0,
      setup_fee: 0
    ).tap do |structure|
      FactoryBot.create(
        :contract_banded_fee_structure_band,
        banded_fee_structure: structure,
        min_declarations: 1,
        max_declarations: band_max,
        fee_per_declaration: 100,
        output_fee_ratio: 1.0,
        service_fee_ratio: 0.0
      )
      structure.bands.reload
    end
  end

  let(:contract) do
    FactoryBot.create(:contract, :for_ecf, active_lead_provider:, banded_fee_structure:)
  end
  let(:statement) do
    FactoryBot.create(
      :statement,
      contract:,
      active_lead_provider:,
      month: 11,
      year: 2024,
      payment_date: Date.new(2024, 11, 25),
      deadline_date: Date.new(2024, 10, 31)
    )
  end

  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      lead_provider_delivery_partnership: FactoryBot.create(
        :lead_provider_delivery_partnership,
        active_lead_provider:
      )
    )
  end
  let(:default_training_period_attrs) do
    {
      school_partnership:,
      started_on: Date.new(2024, 10, 1)
    }
  end

  let(:base_declaration_date) { Time.zone.local(2025, 11, 10, 10) }
  let(:default_declaration_attrs) do
    {
      payment_status: :paid,
      clawback_status: :no_clawback,
      declaration_type: :started,
      declaration_date: base_declaration_date,
      created_at: base_declaration_date
    }
  end

  let(:banded_calculator) do
    PaymentCalculator::Banded.new(
      statement:,
      banded_fee_structure:,
      declaration_selector: ->(declarations) { declarations }
    )
  end
  let(:calculators) { [banded_calculator] }

  before do
    resolver_double = instance_double(PaymentCalculator::Resolver, calculators:)
    allow(PaymentCalculator::Resolver).to receive(:new).with(statement:).and_return(resolver_double)
  end

  context "when all linked declarations fit inside available capacity" do
    let!(:current_billable_earliest_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:current_billable_later_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "returns all linked declarations" do
      expect(selected_declaration_ids).to contain_exactly(
        current_billable_earliest_declaration.id,
        current_billable_later_declaration.id
      )
    end
  end

  context "when declarations exceed band capacity" do
    let(:band_max) { 2 }

    let!(:earlier_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:middle_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:later_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 2.days,
          created_at: base_declaration_date + 2.days
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "keeps only declarations that fit capacity using chronological order" do
      expect(selected_declaration_ids).to eq([earlier_declaration.id, middle_declaration.id])
    end
  end

  context "when declarations tie on declaration_date and created_at" do
    let(:band_max) { 2 }

    let!(:same_timestamp_declaration_one) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:same_timestamp_declaration_two) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:same_timestamp_declaration_three) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "uses id as a deterministic tiebreaker" do
      expect(selected_declaration_ids).to eq([
        same_timestamp_declaration_one.id,
        same_timestamp_declaration_two.id
      ])
    end
  end

  context "when the statement contains clawbacks" do
    let(:previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 25),
        deadline_date: Date.new(2024, 9, 30)
      )
    end
    let!(:clawback_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: previous_statement,
          clawback_statement: statement,
          clawback_status: :awaiting_clawback
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "includes refundable declarations counted on this statement" do
      expect(selected_declaration_ids).to include(clawback_declaration.id)
    end
  end

  context "when resolver returns a flat rate calculator" do
    let(:flat_rate_calculator) do
      PaymentCalculator::FlatRate.new(
        statement:,
        flat_rate_fee_structure: nil,
        declaration_selector: ->(declarations) {
          declarations.with_declaration_types(%i[started completed])
        },
        fee_proportions: {}
      )
    end
    let(:calculators) { [flat_rate_calculator] }

    let(:previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 25),
        deadline_date: Date.new(2024, 9, 30)
      )
    end

    let!(:started_billable_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_type: :started,
          declaration_date: base_declaration_date,
          created_at: base_declaration_date
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:retained_billable_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_type: "retained-1",
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:completed_billable_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_type: :completed,
          declaration_date: base_declaration_date + 2.days,
          created_at: base_declaration_date + 2.days
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:started_refundable_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: previous_statement,
          clawback_statement: statement,
          clawback_status: :awaiting_clawback,
          declaration_type: :started,
          declaration_date: base_declaration_date + 3.days,
          created_at: base_declaration_date + 3.days
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "includes only started/completed declarations across current billable and current refundable sets in order" do
      expect(selected_declaration_ids).to eq([
        started_billable_declaration.id,
        completed_billable_declaration.id,
        started_refundable_declaration.id,
      ])
    end
  end

  context "when resolver returns an unsupported calculator type" do
    let(:calculators) { [Object.new] }

    it "raises an explicit unsupported calculator error" do
      expect { selected_declaration_ids }
        .to raise_error(described_class::UnsupportedCalculatorError, "Unsupported calculator: Object")
    end
  end

  context "when a declaration is selected by multiple calculators" do
    let(:flat_rate_calculator) do
      PaymentCalculator::FlatRate.new(
        statement:,
        flat_rate_fee_structure: nil,
        declaration_selector: ->(declarations) { declarations },
        fee_proportions: {}
      )
    end
    let(:calculators) { [banded_calculator, flat_rate_calculator] }

    let!(:shared_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "returns each declaration id once" do
      expect(selected_declaration_ids).to eq([shared_declaration.id])
    end
  end

  context "when previous statements already consume all band capacity" do
    let(:band_max) { 2 }

    let(:previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 25),
        deadline_date: Date.new(2024, 9, 30)
      )
    end

    let!(:previous_billable_earlier_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: previous_statement,
          declaration_date: base_declaration_date,
          created_at: base_declaration_date
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:previous_billable_later_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: previous_statement,
          declaration_date: base_declaration_date + 1.hour,
          created_at: base_declaration_date + 1.hour
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:current_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "returns no current declaration ids for the exhausted declaration type" do
      expect(selected_declaration_ids).to eq([])
    end
  end

  context "when same payment date statements exist" do
    let(:band_max) { 2 }

    let(:qualifying_previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 25),
        deadline_date: Date.new(2024, 9, 30)
      )
    end
    let(:same_payment_date_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 12,
        year: 2024,
        payment_date: statement.payment_date,
        deadline_date: Date.new(2024, 11, 30)
      )
    end

    let!(:qualifying_previous_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: qualifying_previous_statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:same_payment_date_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: same_payment_date_statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:current_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "ignores statements that are not strictly earlier by payment_date" do
      expect(selected_declaration_ids).to eq([current_declaration.id])
    end
  end

  context "when statements from another provider exist" do
    let(:band_max) { 2 }

    let(:qualifying_previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract:,
        active_lead_provider:,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 25),
        deadline_date: Date.new(2024, 9, 30)
      )
    end
    let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:other_active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider: other_lead_provider,
        contract_period:
      )
    end
    let(:other_contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider: other_active_lead_provider) }
    let(:other_previous_statement) do
      FactoryBot.create(
        :statement,
        :paid,
        contract: other_contract,
        active_lead_provider: other_active_lead_provider,
        month: 10,
        year: 2024,
        payment_date: Date.new(2024, 10, 20),
        deadline_date: Date.new(2024, 9, 25)
      )
    end

    let(:other_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        lead_provider_delivery_partnership: FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: other_active_lead_provider
        )
      )
    end
    let(:other_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :ongoing,
        school_partnership: other_school_partnership,
        started_on: Date.new(2024, 10, 1)
      )
    end

    let!(:qualifying_previous_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: qualifying_previous_statement),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end
    let!(:other_provider_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(payment_statement: other_previous_statement),
        training_period: other_training_period
      )
    end
    let!(:current_declaration) do
      FactoryBot.create(
        :declaration,
        **default_declaration_attrs.merge(
          payment_statement: statement,
          declaration_date: base_declaration_date + 1.day,
          created_at: base_declaration_date + 1.day
        ),
        training_period: FactoryBot.create(:training_period, :for_ect, :ongoing, **default_training_period_attrs)
      )
    end

    it "ignores statements outside the current lead provider" do
      expect(selected_declaration_ids).to eq([current_declaration.id])
    end
  end
end
