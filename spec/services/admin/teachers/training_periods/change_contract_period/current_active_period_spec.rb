RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriod::CurrentActivePeriod do
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
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: current_contract_period.year, school:) }
  let(:target_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let!(:target_schedule) { FactoryBot.create(:schedule, contract_period: target_contract_period, identifier: schedule.identifier) }
  let(:started_on) { today.prev_month }
  let(:finished_on) { nil }
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher:,
      school:,
      started_on: today.prev_year,
      finished_on: nil
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      ect_at_school_period:,
      school_partnership:,
      schedule:,
      started_on:,
      finished_on:
    )
  end

  around do |example|
    travel_to(today) { perform_enqueued_jobs { example.run } }
  end

  it "ends the current training period and creates a replacement in the selected contract period" do
    replacement_training_period = nil

    expect {
      replacement_training_period = service_call
    }
      .to change(TrainingPeriod, :count).by(1)
      .and change { Event.where(event_type: "teacher_training_period_contract_period_changed").count }.by(1)

    expect(training_period.reload.finished_on).to eq(today.yesterday)
    expect(replacement_training_period.started_on).to eq(today)
    expect(replacement_training_period.finished_on).to be_nil
    expect(replacement_training_period.school_partnership).to eq(target_school_partnership)
    expect(replacement_training_period.contract_period).to eq(target_contract_period)
    expect(replacement_training_period.schedule).to eq(target_schedule)
    expect(replacement_training_period.expression_of_interest).to be_nil
  end

  it "does not record a teacher schedule change event" do
    expect {
      service_call
    }.not_to(change { Event.where(event_type: "teacher_changes_schedule_training_period").count })
  end

  context "when the current training period only has an expression of interest" do
    let(:target_school_partnership) { nil }
    let(:current_active_lead_provider) do
      FactoryBot.create(:active_lead_provider, contract_period: current_contract_period)
    end
    let!(:target_active_lead_provider) do
      FactoryBot.create(:active_lead_provider, lead_provider: current_active_lead_provider.lead_provider, contract_period: target_contract_period)
    end
    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :ongoing,
        :with_only_expression_of_interest,
        ect_at_school_period:,
        expression_of_interest: current_active_lead_provider,
        schedule:,
        started_on:,
        finished_on:
      )
    end

    it "ends the current period and creates a replacement with the equivalent active lead provider" do
      replacement_training_period = nil

      expect {
        replacement_training_period = service_call
      }
        .to change(TrainingPeriod, :count).by(1)
        .and change { Event.where(event_type: "teacher_training_period_contract_period_changed").count }.by(1)

      event = Event.where(event_type: "teacher_training_period_contract_period_changed").sole

      expect(training_period.reload.finished_on).to eq(today.yesterday)
      expect(replacement_training_period.started_on).to eq(today)
      expect(replacement_training_period.finished_on).to be_nil
      expect(replacement_training_period.school_partnership).to be_nil
      expect(replacement_training_period.expression_of_interest).to eq(target_active_lead_provider)
      expect(replacement_training_period.expression_of_interest.lead_provider).to eq(current_active_lead_provider.lead_provider)
      expect(replacement_training_period.expression_of_interest_contract_period).to eq(target_contract_period)
      expect(replacement_training_period.schedule).to eq(target_schedule)
      expect(event.metadata["new_training_period_id"]).to eq(replacement_training_period.id)
    end
  end

  context "when the current training period has a future end date" do
    let(:finished_on) { today.next_month }

    it "carries the future end date onto the replacement period" do
      replacement_training_period = service_call

      expect(replacement_training_period.finished_on).to eq(finished_on)
    end
  end

  context "when the training period is not the current active period" do
    let(:started_on) { today.next_month }

    it "raises an unsupported training period error" do
      expect {
        service_call
      }.to raise_error(
        described_class::UnsupportedTrainingPeriodError,
        "Contract period changes are only supported for the current active training period"
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

  context "for ECT training" do
    context "when moving away from a frozen contract period" do
      let(:current_contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }

      it "tracks the frozen year on the teacher" do
        service_call

        expect(teacher.reload.ect_payments_frozen_year).to eq(current_contract_period.year)
      end
    end

    context "when moving back to a frozen contract period" do
      let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025, payments_frozen_at: nil) }
      let(:target_contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }
      let(:teacher) { FactoryBot.create(:teacher, ect_payments_frozen_year: target_contract_period.year) }

      it "clears the frozen year on the teacher" do
        service_call

        expect(teacher.reload.ect_payments_frozen_year).to be_nil
        expect(teacher.reload.mentor_payments_frozen_year).to be_nil
      end
    end
  end

  context "for mentor training" do
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, started_on: today.prev_year) }
    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_mentor,
        :ongoing,
        mentor_at_school_period:,
        school_partnership:,
        schedule:,
        started_on:,
        finished_on:
      )
    end

    it "creates a replacement mentor training period" do
      replacement_training_period = nil

      expect {
        replacement_training_period = service_call
      }.to change(TrainingPeriod, :count).by(1)

      expect(training_period.reload.finished_on).to eq(today.yesterday)
      expect(replacement_training_period.started_on).to eq(today)
      expect(replacement_training_period.school_partnership).to eq(target_school_partnership)
      expect(replacement_training_period.schedule).to eq(target_schedule)
    end

    context "when moving away from a frozen contract period" do
      let(:current_contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }

      it "tracks the frozen year on the mentor field" do
        service_call

        expect(teacher.reload.mentor_payments_frozen_year).to eq(current_contract_period.year)
        expect(teacher.ect_payments_frozen_year).to be_nil
      end
    end

    context "when moving back to a frozen contract period" do
      let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025, payments_frozen_at: nil) }
      let(:target_contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }
      let(:teacher) { FactoryBot.create(:teacher, mentor_payments_frozen_year: target_contract_period.year) }

      it "clears the frozen year on the mentor field" do
        service_call

        expect(teacher.reload.mentor_payments_frozen_year).to be_nil
        expect(teacher.reload.ect_payments_frozen_year).to be_nil
      end
    end
  end
end
