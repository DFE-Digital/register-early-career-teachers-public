RSpec.describe TouchSchoolPartnershipForParticipantsCurrentlyTrainingJob, type: :job do
  let(:instance) { described_class.new }

  around { |example| freeze_time { example.run } }

  describe "#perform" do
    subject(:perform) { instance.perform }

    let(:school_partnership) { FactoryBot.create(:school_partnership, api_updated_at: 1.week.ago) }

    before do
      ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on:, finished_on:)
      FactoryBot.create(:training_period, started_on:, finished_on:, school_partnership:, ect_at_school_period:)
    end

    context "when a training period starts today" do
      let(:started_on) { Time.zone.today }
      let(:finished_on) { nil }

      it { expect { perform }.to change { school_partnership.reload.api_updated_at }.to eq(Time.current) }
    end

    context "when a training period finished yesterday" do
      let(:started_on) { 1.week.ago }
      let(:finished_on) { Time.zone.yesterday }

      it { expect { perform }.to change { school_partnership.reload.api_updated_at }.to eq(Time.current) }
    end

    context "when a training period starts after today" do
      let(:started_on) { Time.zone.tomorrow }
      let(:finished_on) { 1.week.from_now }

      it { expect { perform }.not_to(change { school_partnership.reload.api_updated_at }) }
    end

    context "when a training period finished before yesterday" do
      let(:started_on) { 2.weeks.ago }
      let(:finished_on) { 2.days.ago }

      it { expect { perform }.not_to(change { school_partnership.reload.api_updated_at }) }
    end

    context "when a training period starts before today and finishes after yesterday" do
      let(:started_on) { Time.zone.yesterday }
      let(:finished_on) { Time.zone.tomorrow }

      it { expect { perform }.not_to(change { school_partnership.reload.api_updated_at }) }
    end

    context "when there are multiple school partnerships with training periods starting today" do
      let(:started_on) { Time.zone.today }
      let(:finished_on) { nil }

      let(:another_school_partnership) { FactoryBot.create(:school_partnership, api_updated_at: 2.weeks.ago) }

      before do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on:, finished_on:)
        FactoryBot.create(:training_period, started_on:, finished_on:, school_partnership: another_school_partnership, ect_at_school_period:)
      end

      it "updates all relevant school partnerships" do
        expect { perform }.to change { school_partnership.reload.api_updated_at }.and(change { another_school_partnership.reload.api_updated_at })

        timestamps = [school_partnership.api_updated_at, another_school_partnership.api_updated_at]
        expect(timestamps).to all(eq(Time.current))
      end
    end
  end
end
