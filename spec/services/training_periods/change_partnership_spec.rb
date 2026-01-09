RSpec.describe TrainingPeriods::ChangePartnership do
  include ActiveJob::TestHelper

  subject(:service_call) do
    described_class.new(training_period:, school_partnership: other_school_partnership, author:).call
  end

  let(:author) { Events::SystemAuthor.new }
  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, school:, lead_provider:, delivery_partner:) }
  let(:other_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, school:, lead_provider: other_lead_provider, delivery_partner: other_delivery_partner) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period:) }

  context "when the training period is at least one day old and ongoing" do
    let(:today) { Date.new(2025, 2, 1) }
    let(:started_on) { today - 2.days }
    let(:ect_period) { FactoryBot.create(:ect_at_school_period, school:, started_on:, finished_on: nil) }
    let!(:training_period) { FactoryBot.create(:training_period, ect_at_school_period: ect_period, school_partnership:, schedule:, started_on:, finished_on: nil) }

    it "finishes the current period and creates a new one" do
      travel_to(today) do
        expect { perform_enqueued_jobs { service_call } }
          .to change(TrainingPeriod, :count).by(1)
          .and change { Event.where(event_type: "teacher_finishes_training_period").count }.by(1)
          .and change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)
        expect(training_period.reload.finished_on).to eq(today)
        replacement = TrainingPeriod.where(ect_at_school_period: ect_period).where.not(id: training_period.id).order(created_at: :desc).first
        expect(replacement.school_partnership).to eq(other_school_partnership)
        expect(replacement.expression_of_interest).to be_nil
        expect(replacement.started_on).to eq(today)
        expect(replacement.finished_on).to be_nil
      end
    end
  end

  context "when the training period starts today and is ongoing" do
    let(:today) { Date.new(2025, 2, 1) }
    let(:started_on) { today }
    let(:ect_period) { FactoryBot.create(:ect_at_school_period, school:, started_on:, finished_on: nil) }
    let!(:training_period) { FactoryBot.create(:training_period, ect_at_school_period: ect_period, school_partnership:, schedule:, started_on:, finished_on: nil) }

    it "updates the training period in place" do
      travel_to(today) do
        expect { perform_enqueued_jobs { service_call } }
          .to not_change(TrainingPeriod, :count)
          .and change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)
        expect(training_period.reload.school_partnership).to eq(other_school_partnership)
        expect(training_period.expression_of_interest).to be_nil
        expect(training_period.finished_on).to be_nil
      end
    end
  end

  context "when required arguments are missing" do
    let(:training_period) { FactoryBot.create(:training_period) }

    it "raises when training_period is nil" do
      expect {
        described_class.new(training_period: nil, school_partnership: other_school_partnership, author:).call
      }.to raise_error(ArgumentError, "training_period is required")
    end

    it "raises when school_partnership is nil" do
      expect {
        described_class.new(training_period:, school_partnership: nil, author:).call
      }.to raise_error(ArgumentError, "school_partnership is required")
    end
  end
end
