RSpec.describe API::TrainingPeriods::TrainingStatus do
  let(:service) { described_class.new(training_period:) }

  describe "#status" do
    subject { service.status }

    context "when the training period is neither withdrawn nor deferred" do
      let(:training_period) { FactoryBot.build(:training_period) }

      it { is_expected.to eq(:active) }
      it { expect(service).to be_active }
      it { expect(service).not_to be_withdrawn }
      it { expect(service).not_to be_deferred }
    end

    context "when the training period is withdrawn" do
      let(:training_period) { FactoryBot.build(:training_period, :withdrawn) }

      it { is_expected.to eq(:withdrawn) }
      it { expect(service).to be_withdrawn }
      it { expect(service).not_to be_active }
      it { expect(service).not_to be_deferred }
    end

    context "when the training period is deferred" do
      let(:training_period) { FactoryBot.build(:training_period, :deferred) }

      it { is_expected.to eq(:deferred) }
      it { expect(service).to be_deferred }
      it { expect(service).not_to be_active }
      it { expect(service).not_to be_withdrawn }
    end
  end
end
