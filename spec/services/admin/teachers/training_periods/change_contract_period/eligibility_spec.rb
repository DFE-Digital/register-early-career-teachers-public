RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriod::Eligibility do
  subject(:eligibility) { described_class.new(training_period:) }

  let(:today) { Date.new(2026, 2, 1) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_school) { FactoryBot.create(:school) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      :for_year,
      year: contract_period.year,
      lead_provider:,
      delivery_partner:
    )
  end
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      school:,
      lead_provider_delivery_partnership:
    )
  end
  let(:started_on) { today.prev_month }
  let(:finished_on) { nil }
  let(:current_started_on) { today.prev_month }
  let(:current_finished_on) { nil }
  let(:current_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      school: current_school,
      lead_provider_delivery_partnership:
    )
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school:,
      started_on:,
      finished_on:
    )
  end
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      ect_at_school_period:,
      school_partnership:,
      started_on:,
      finished_on:
    )
  end
  let(:current_ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school: current_school,
      started_on: current_started_on,
      finished_on: current_finished_on
    )
  end
  let(:current_training_period) do
    FactoryBot.create(
      :training_period,
      ect_at_school_period: current_ect_at_school_period,
      school_partnership: current_school_partnership,
      started_on: current_started_on,
      finished_on: current_finished_on
    )
  end

  around do |example|
    travel_to(today) { example.run }
  end

  it "is eligible for a provider-led active current period with no future periods" do
    expect(eligibility).to be_eligible
  end

  context "when the training period is not provider-led" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :school_led,
        ect_at_school_period:,
        started_on:,
        finished_on:
      )
    end

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end

  context "when the training period has no partnership" do
    let(:training_period) do
      FactoryBot.create(
        :training_period,
        :with_only_expression_of_interest,
        ect_at_school_period:,
        started_on:,
        finished_on:
      )
    end

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end

  context "when the training period has ended" do
    let(:started_on) { today.prev_year }
    let(:finished_on) { today.yesterday }

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end

  context "when there is only one future period and no current active period" do
    let(:started_on) { today.next_month }

    it "is eligible" do
      expect(eligibility).to be_eligible
    end
  end

  context "when there is more than one future period and no current active period" do
    let(:started_on) { today.next_month }
    let(:second_future_started_on) { started_on.next_month }
    let(:finished_on) { second_future_started_on.yesterday }

    before do
      FactoryBot.create(
        :training_period,
        ect_at_school_period: FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school:,
          started_on: second_future_started_on,
          finished_on: nil
        ),
        school_partnership:,
        started_on: second_future_started_on,
        finished_on: nil
      )
    end

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end

  context "when the future period has the same lead provider and delivery partner as the current active period" do
    let(:started_on) { today.next_month }
    let(:current_finished_on) { started_on.yesterday }

    before do
      training_period
      current_training_period
    end

    it "is eligible" do
      expect(eligibility).to be_eligible
    end

    it "does not make the current active period eligible" do
      expect(described_class.new(training_period: current_training_period)).not_to be_eligible
    end
  end

  context "when the future period has a different lead provider" do
    let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:future_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        :for_year,
        year: contract_period.year,
        school:,
        lead_provider: other_lead_provider,
        delivery_partner:
      )
    end
    let(:started_on) { today.next_month }
    let(:current_finished_on) { started_on.yesterday }
    let(:school_partnership) { future_school_partnership }

    before do
      current_training_period
    end

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end

  context "when the future period has a different delivery partner" do
    let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:future_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        :for_year,
        year: contract_period.year,
        school:,
        lead_provider:,
        delivery_partner: other_delivery_partner
      )
    end
    let(:started_on) { today.next_month }
    let(:current_finished_on) { started_on.yesterday }
    let(:school_partnership) { future_school_partnership }

    before do
      current_training_period
    end

    it "is not eligible" do
      expect(eligibility).not_to be_eligible
    end
  end
end
