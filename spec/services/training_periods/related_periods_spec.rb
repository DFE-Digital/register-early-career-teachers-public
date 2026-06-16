RSpec.describe TrainingPeriods::RelatedPeriods do
  subject(:relationships) { described_class.new(training_period:) }

  let(:today) { Date.new(2026, 2, 1) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:current_period_started_on) { today.prev_year }
  let(:current_period_finished_on) { nil }
  let(:current_ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      started_on: current_period_started_on,
      finished_on: current_period_finished_on
    )
  end
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      ect_at_school_period: current_ect_at_school_period,
      started_on: current_period_started_on,
      finished_on: current_period_finished_on
    )
  end

  around do |example|
    travel_to(today) { example.run }
  end

  context "when there are no future periods" do
    it "returns no future periods" do
      expect(relationships.future_periods).to be_empty
    end

    it "returns the given period as the current active period" do
      expect(relationships.current_active_period).to eq(training_period)
    end
  end

  context "when there are current, historical and future sibling periods" do
    let(:future_start) { today.next_month }
    let(:current_period_finished_on) { future_start.yesterday }
    let(:historical_started_on) { today.prev_year(2) }
    let(:historical_finished_on) { today.months_ago(18) }
    let(:historical_ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: historical_started_on,
        finished_on: historical_finished_on
      )
    end
    let!(:historical_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: historical_ect_at_school_period,
        started_on: historical_started_on,
        finished_on: historical_finished_on
      )
    end

    let(:future_ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: future_start,
        finished_on: future_start.next_month
      )
    end
    let!(:future_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: future_ect_at_school_period,
        started_on: future_start,
        finished_on: future_start.next_month
      )
    end

    let(:later_future_ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: future_start.months_since(2),
        finished_on: nil
      )
    end
    let!(:later_future_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: later_future_ect_at_school_period,
        started_on: future_start.months_since(2),
        finished_on: nil
      )
    end

    it "returns the active period for today" do
      expect(relationships.current_active_period).to eq(training_period)
    end

    it "returns future periods" do
      expect(relationships.future_periods).to contain_exactly(future_period, later_future_period)
    end

    it "does not include historical periods in future periods" do
      expect(relationships.future_periods).not_to include(historical_period)
    end
  end

  context "when there are future periods for another participant role" do
    let(:mentor_started_on) { today.next_month }
    let(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        started_on: mentor_started_on,
        finished_on: nil
      )
    end

    before do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        mentor_at_school_period:,
        started_on: mentor_started_on,
        finished_on: nil
      )
    end

    it "does not include future periods for another participant role" do
      expect(relationships.future_periods).to be_empty
    end
  end
end
