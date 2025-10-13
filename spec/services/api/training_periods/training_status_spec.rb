RSpec.describe API::TrainingPeriods::TrainingStatus do
  let(:service) { described_class.new(training_period:) }

  describe "#status" do
    subject { service.status }

    context "when the training period is neither withdrawn nor deferred" do
      let(:training_period) { FactoryBot.build(:training_period) }

      it { is_expected.to eq(:active) }
    end

    context "when the training period is withdrawn" do
      let(:training_period) { FactoryBot.build(:training_period, :withdrawn) }

      it { is_expected.to eq(:withdrawn) }
    end

    context "when the training period is deferred" do
      let(:training_period) { FactoryBot.build(:training_period, :deferred) }

      it { is_expected.to eq(:deferred) }
    end
  end
end
