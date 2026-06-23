RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriod::FuturePeriod do
  include ActiveJob::TestHelper

  subject(:service_call) do
    described_class.new(
      training_period:,
      contract_period: target_contract_period,
      school_partnership: target_school_partnership,
      author:
    ).change_contract_period!
  end

  let(:today) { Date.new(2026, 2, 1) }
  let(:author) { Events::SystemAuthor.new }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:current_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      school: current_school,
      lead_provider_delivery_partnership: school_partnership.lead_provider_delivery_partnership
    )
  end
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: current_contract_period.year,
      school:
    )
  end
  let(:target_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: target_contract_period.year,
      school:,
      lead_provider: school_partnership.lead_provider,
      delivery_partner: school_partnership.delivery_partner
    )
  end
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let!(:target_schedule) { FactoryBot.create(:schedule, contract_period: target_contract_period, identifier: schedule.identifier) }
  let(:future_started_on) { today.next_month }
  let(:future_finished_on) { future_started_on.next_year }
  let(:current_ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school: current_school,
      started_on: today.prev_year,
      finished_on: future_started_on.yesterday
    )
  end
  let(:future_ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school:,
      started_on: future_started_on,
      finished_on: nil
    )
  end
  let!(:current_training_period) do
    FactoryBot.create(
      :training_period,
      ect_at_school_period: current_ect_at_school_period,
      school_partnership: current_school_partnership,
      schedule:,
      started_on: today.prev_month,
      finished_on: future_started_on.yesterday
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      ect_at_school_period: future_ect_at_school_period,
      school_partnership:,
      schedule:,
      started_on: future_started_on,
      finished_on: future_finished_on
    )
  end

  around do |example|
    travel_to(today) { perform_enqueued_jobs { example.run } }
  end

  it "updates the future training period in place" do
    expect {
      service_call
    }
      .to not_change(TrainingPeriod, :count)
      .and change { Event.where(event_type: "teacher_training_period_contract_period_changed").count }.by(1)

    expect(training_period.reload).to have_attributes(
      teacher_id: teacher.id,
      ect_at_school_period_id: future_ect_at_school_period.id,
      mentor_at_school_period_id: nil,
      started_on: future_started_on,
      finished_on: future_finished_on
    )
    expect(training_period.school_partnership).to eq(target_school_partnership)
    expect(training_period.contract_period).to eq(target_contract_period)
    expect(training_period.schedule).to eq(target_schedule)
    expect(current_training_period.reload.finished_on).to eq(future_started_on.yesterday)
  end

  context "when there is only a future training period" do
    let!(:current_training_period) { nil }

    it "updates the future training period in place" do
      expect {
        service_call
      }.not_to change(TrainingPeriod, :count)

      expect(training_period.reload.school_partnership).to eq(target_school_partnership)
      expect(training_period.schedule).to eq(target_schedule)
    end
  end

  context "when the future training period has a different LP/DP from the current active period" do
    let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:current_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        :for_year,
        year: current_contract_period.year,
        school: current_school,
        lead_provider: school_partnership.lead_provider,
        delivery_partner: other_delivery_partner
      )
    end

    it "raises an unsupported training period error" do
      expect {
        service_call
      }.to raise_error(
        described_class::UnsupportedTrainingPeriodError,
        "Contract period changes are only supported for eligible future training periods"
      )
    end
  end

  context "when there is no equivalent schedule in the selected contract period" do
    let!(:target_schedule) { nil }

    it "raises a schedule not found error" do
      expect {
        service_call
      }.to raise_error(
        described_class::ScheduleNotFoundError,
        "No equivalent schedule found for #{schedule.identifier} in contract period #{target_contract_period.year}"
      )
    end
  end
end
