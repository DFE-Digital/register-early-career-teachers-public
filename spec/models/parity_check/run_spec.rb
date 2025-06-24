describe ParityCheck::Run do
  it { expect(described_class).to have_attributes(table_name: "parity_check_runs") }

  describe "associations" do
    it { is_expected.to have_many(:requests).dependent(:destroy) }
  end

  describe "defaults" do
    it { is_expected.to have_attributes(mode: "concurrent") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:mode) }
    it { is_expected.to validate_inclusion_of(:mode).in_array(%w[concurrent sequential]) }
    it { is_expected.not_to validate_presence_of(:started_at) }
    it { is_expected.not_to validate_presence_of(:completed_at) }
    it { is_expected.not_to validate_uniqueness_of(:state) }

    context "when in_progress" do
      subject { FactoryBot.build(:parity_check_run, :in_progress) }

      it { is_expected.to validate_presence_of(:started_at) }
      it { is_expected.to validate_uniqueness_of(:state) }
    end

    context "when completed" do
      subject { FactoryBot.build(:parity_check_run, :completed, started_at:) }

      let(:started_at) { Time.current }

      it { is_expected.to validate_presence_of(:completed_at) }
      it { is_expected.to allow_values(started_at, started_at + 1.second).for(:completed_at) }
      it { is_expected.not_to allow_values(nil, started_at - 1.second).for(:completed_at) }
    end
  end

  describe "scopes" do
    let!(:pending_run) { FactoryBot.create(:parity_check_run, :pending) }
    let!(:in_progress_run) { FactoryBot.create(:parity_check_run, :in_progress) }
    let!(:completed_run) { FactoryBot.create(:parity_check_run, :completed) }

    describe ".pending" do
      subject { described_class.pending }

      it { is_expected.to contain_exactly(pending_run) }
    end

    describe ".in_progress" do
      subject { described_class.in_progress }

      it { is_expected.to contain_exactly(in_progress_run) }
    end
  end

  describe "state transitions" do
    it { is_expected.to be_pending }

    context "when transitioning from pending to in_progress" do
      let(:run) { FactoryBot.create(:parity_check_run, :pending) }

      it { expect { run.in_progress! }.to change(run, :state).from("pending").to("in_progress") }
      it { expect { run.in_progress! }.to change(run, :started_at).from(nil).to(be_within(1.second).of(Time.zone.now)) }
    end

    context "when transitioning from in_progress to completed" do
      let(:run) { FactoryBot.create(:parity_check_run, :in_progress) }

      it { expect { run.complete! }.to change(run, :state).from("in_progress").to("completed") }
      it { expect { run.complete! }.to change(run, :completed_at).from(nil).to(be_within(1.second).of(Time.zone.now)) }
    end
  end

  describe "#progress" do
    subject { run.progress }

    let(:run) { FactoryBot.create(:parity_check_run, requests:) }

    context "when there are no requests" do
      let(:requests) { [] }

      it { is_expected.to eq(0) }
    end

    context "when there are no completed requests" do
      let(:requests) { FactoryBot.create_list(:parity_check_request, 3, :pending) }

      it { is_expected.to eq(0) }
    end

    context "when there are requests in various states" do
      let(:requests) do
        [
          FactoryBot.create(:parity_check_request, :completed),
          FactoryBot.create(:parity_check_request, :completed),
          FactoryBot.create(:parity_check_request, :completed),
          FactoryBot.create(:parity_check_request, :in_progress),
          FactoryBot.create(:parity_check_request, :queued),
          FactoryBot.create(:parity_check_request, :pending),
          FactoryBot.create(:parity_check_request, :pending),
        ]
      end

      it { is_expected.to eq(43) }
    end

    context "when all requests are completed" do
      let(:requests) { FactoryBot.create_list(:parity_check_request, 3, :completed) }

      it { is_expected.to eq(100) }
    end
  end

  describe "#estimated_completion_at" do
    subject { run.estimated_completion_at }

    let(:started_at) { 1.hour.ago }
    let(:run) { FactoryBot.create(:parity_check_run, state, requests:, started_at:) }

    context "when the run is in progress" do
      let(:state) { :in_progress }
      let(:requests) do
        [
          FactoryBot.create(:parity_check_request, :completed),
          FactoryBot.create(:parity_check_request, :completed),
          FactoryBot.create(:parity_check_request, :in_progress),
          FactoryBot.create(:parity_check_request, :in_progress),
        ]
      end

      it { is_expected.to be_within(1.second).of(started_at + 2.hours) }

      context "when the run has no requests" do
        let(:requests) { [] }

        it { is_expected.to be_nil }
      end

      context "when no requests have been completed yet" do
        let(:requests) { FactoryBot.create_list(:parity_check_request, 3, :in_progress) }

        it { is_expected.to be_nil }
      end
    end

    context "when the run is not in progress" do
      let(:state) { :completed }
      let(:requests) { FactoryBot.create_list(:parity_check_request, 3, :completed) }

      it { is_expected.to be_nil }
    end
  end
end
