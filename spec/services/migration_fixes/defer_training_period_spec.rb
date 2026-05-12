describe MigrationFixes::DeferTrainingPeriod do
  subject(:service) { described_class.new(training_period:, deferred_at:, deferral_reason:) }

  let(:teacher) { FactoryBot.create(:teacher, api_updated_at:) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, started_on:) }
  let!(:training_period) { FactoryBot.create(:training_period, :for_ect, started_on:, finished_on:, ect_at_school_period:, updated_at:) }
  let(:deferred_at) { 1.week.ago.round }
  let(:deferral_reason) { "career_break" }
  let(:started_on) { 1.year.ago.to_date }
  let(:finished_on) { nil }
  let(:api_updated_at) { 1.day.ago.round }
  let(:updated_at) { 1.month.ago.round }

  describe "#defer!" do
    before do
      service.defer!
    end

    it "sets the finished_on to the deferral date" do
      expect(training_period.finished_on).to eq(deferred_at.to_date)
    end

    it "sets the deferred_at to the deferral date" do
      expect(training_period.deferred_at).to eq(deferred_at)
    end

    it "sets the deferral_reason" do
      expect(training_period.deferral_reason).to eq(deferral_reason)
    end

    it "does not change the updated_at" do
      expect(training_period.updated_at).to eq(updated_at)
    end

    it "does not change the teacher api_updated_at" do
      expect(teacher.reload.api_updated_at).to eq(api_updated_at)
    end

    context "when the period is already closed" do
      let(:finished_on) { 2.weeks.ago.to_date }

      it "sets the deferred_at to the finished_on date" do
        expect(training_period.deferred_at.to_date).to eq(finished_on)
      end

      it "sets the deferral_reason" do
        expect(training_period.deferral_reason).to eq(deferral_reason)
      end

      it "does not change the updated_at" do
        expect(training_period.updated_at).to eq(updated_at)
      end
    end

    context "when the period is already deferred" do
      let(:finished_on) { 2.weeks.ago.to_date }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, started_on:, finished_on:, ect_at_school_period:, updated_at:, deferred_at: finished_on, deferral_reason: "other") }

      it "does not change the deferred_at" do
        expect(training_period.deferred_at.to_date).to eq(finished_on)
      end

      it "does not change the deferral_reason" do
        expect(training_period.deferral_reason).to eq("other")
      end

      it "does not change the updated_at" do
        expect(training_period.updated_at).to eq(updated_at)
      end
    end
  end
end
