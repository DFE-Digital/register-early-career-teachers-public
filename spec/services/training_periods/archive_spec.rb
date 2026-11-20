RSpec.describe TrainingPeriods::Archive do
  describe ".call" do
    let(:training_period) { FactoryBot.create(:training_period) }

    it "archives the training period" do
      described_class.call(training_period)

      expect(training_period.reload).to be_archived
    end
  end
end
