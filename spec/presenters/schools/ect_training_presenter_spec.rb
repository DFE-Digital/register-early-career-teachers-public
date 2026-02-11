RSpec.describe Schools::ECTTrainingPresenter do
  subject { described_class.new(ect_at_school_period) }

  let(:ect_at_school_period) { FactoryBot.build(:ect_at_school_period) }

  describe "#training_period_for_display" do
    context "when current_or_next_training_period is present" do
      let(:current_or_next_training_period) { instance_double(TrainingPeriod) }
      let(:latest_training_period) { instance_double(TrainingPeriod) }

      before do
        allow(ect_at_school_period)
          .to receive(:current_or_next_training_period)
          .and_return(current_or_next_training_period)
      end

      it "returns current_or_next_training_period" do
        expect(subject.training_period_for_display).to eq(current_or_next_training_period)
      end
    end

    context "when current_or_next_training_period is nil" do
      let(:latest_training_period) { instance_double(TrainingPeriod) }

      before do
        allow(ect_at_school_period).to receive(:latest_training_period).and_return(latest_training_period)
      end

      it "returns latest_training_period" do
        expect(subject.training_period_for_display).to eq(latest_training_period)
      end
    end
  end

  describe "#latest_started_training_status" do
    before do
      allow(ect_at_school_period).to receive(:latest_started_training_status).and_return(:withdrawn)
    end

    it "delegates to ect_at_school_period" do
      expect(subject.latest_started_training_status).to eq(:withdrawn)
    end
  end
end
