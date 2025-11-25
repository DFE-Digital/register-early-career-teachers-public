RSpec.describe Teachers::SchoolTransfers::Transfer do
  subject(:transfer) do
    described_class.new(
      leaving_training_period:,
      leaving_school:,
      joining_training_period:,
      joining_school:
    )
  end

  let(:leaving_training_period) { FactoryBot.build_stubbed(:training_period) }
  let(:joining_training_period) { FactoryBot.build_stubbed(:training_period) }
  let(:leaving_school) { FactoryBot.build_stubbed(:school) }
  let(:joining_school) { FactoryBot.build_stubbed(:school) }

  it { is_expected.to delegate_method(:for_ect?).to(:leaving_training_period) }
  it { is_expected.to delegate_method(:for_mentor?).to(:leaving_training_period) }

  describe "#leaving_training_period" do
    subject { transfer.leaving_training_period }

    it { is_expected.to eq(leaving_training_period) }
  end

  describe "#joining_training_period" do
    subject { transfer.joining_training_period }

    it { is_expected.to eq(joining_training_period) }
  end

  describe "#leaving_school" do
    subject { transfer.leaving_school }

    it { is_expected.to eq(leaving_school) }
  end

  describe "#joining_school" do
    subject { transfer.joining_school }

    it { is_expected.to eq(joining_school) }
  end

  describe "#type" do
    subject(:type) { transfer.type }

    context "when there is no joining_training_period" do
      let(:joining_training_period) { nil }

      it { is_expected.to eq(:unknown) }
    end

    context "when the leaving_training_period and joining_training_period " \
            "have different lead providers" do
      let(:leaving_training_period) { FactoryBot.create(:training_period) }
      let(:joining_training_period) { FactoryBot.create(:training_period) }

      it { is_expected.to eq(:new_provider) }
    end

    context "when the leaving_training_period and joining_training_period " \
            "have the same lead provider" do
      it { is_expected.to eq(:new_school) }
    end

    context "when the leaving_training_period and joining_training_period " \
            "have the same lead provider and the leaving_school and " \
            "joining_school are the same" do
      let(:joining_training_period) { leaving_training_period }
      let(:joining_school) { leaving_school }

      it "raises an error" do
        expect { type }.to raise_error(
          Teachers::SchoolTransfers::InvalidTransferError,
          "Unexpected transfer"
        )
      end
    end
  end

  describe "#status" do
    subject(:status) { transfer.status }

    context "when the leaving_training_period finishes in the future" do
      let(:leaving_training_period) do
        FactoryBot.build_stubbed(:training_period, finished_on: 1.day.from_now)
      end
      let(:joining_training_period) do
        FactoryBot.build_stubbed(:training_period, :ongoing)
      end

      it { is_expected.to eq(:incomplete) }
    end

    context "when the joining_training_period starts in the future" do
      let(:leaving_training_period) do
        FactoryBot.build_stubbed(:training_period)
      end
      let(:joining_training_period) do
        FactoryBot.build_stubbed(:training_period, started_on: 1.day.from_now)
      end

      it { is_expected.to eq(:incomplete) }
    end

    context "when the leaving_training_period has finished and the " \
            "joining_training_period has started" do
      let(:leaving_training_period) do
        FactoryBot.build_stubbed(:training_period, finished_on: 1.day.ago)
      end
      let(:joining_training_period) do
        FactoryBot.build_stubbed(:training_period, started_on: 1.day.ago)
      end

      it { is_expected.to eq(:complete) }
    end
  end
end
