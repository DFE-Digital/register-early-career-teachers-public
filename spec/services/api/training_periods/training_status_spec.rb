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

    context "when the training period is both withdrawn and deferred" do
      let(:training_period) { FactoryBot.build(:training_period, withdrawn_at:, deferred_at:) }

      context "when withdrawn_at is more recent than deferred_at" do
        let(:withdrawn_at) { 2.days.ago }
        let(:deferred_at) { 5.days.ago }

        it { is_expected.to eq(:withdrawn) }
        it { expect(service).to be_withdrawn }
        it { expect(service).not_to be_active }
        it { expect(service).not_to be_deferred }
      end

      context "when deferred_at is more recent than withdrawn_at" do
        let(:withdrawn_at) { 5.days.ago }
        let(:deferred_at) { 2.days.ago }

        it { is_expected.to eq(:deferred) }
        it { expect(service).to be_deferred }
        it { expect(service).not_to be_active }
        it { expect(service).not_to be_withdrawn }
      end
    end
  end
end
