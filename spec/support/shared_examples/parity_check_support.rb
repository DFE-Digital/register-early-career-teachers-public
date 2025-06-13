RSpec.shared_examples "completable validations" do
  it { is_expected.not_to validate_presence_of(:started_at) }

  context "when completed_at is set" do
    subject { described_class.new(completed_at: 1.day.ago) }

    it { is_expected.to validate_presence_of(:started_at) }
  end

  describe "completed_at" do
    subject { instance.errors[:completed_at] }

    let(:instance) { described_class.new(started_at:, completed_at:) }
    let(:started_at) { Time.current }

    before { instance.validate }

    context "when completed_at is not set" do
      let(:completed_at) { nil }

      it { is_expected.to be_empty }
    end

    context "when completed_at is equal to started_at" do
      let(:completed_at) { started_at }

      it { is_expected.to be_empty }
    end

    context "when completed_at is greater than started_at" do
      let(:completed_at) { started_at + 1.hour }

      it { is_expected.to be_empty }
    end

    context "when completed_at is before started_at" do
      let(:completed_at) { started_at - 1.hour }

      it { is_expected.to be_present }
    end
  end
end
