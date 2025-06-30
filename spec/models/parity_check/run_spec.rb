describe ParityCheck::Run do
  it { expect(described_class).to have_attributes(table_name: "parity_check_runs") }

  describe "associations" do
    it { is_expected.to have_many(:requests).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:requests) }
    it { is_expected.to have_many(:endpoints).through(:requests) }
    it { is_expected.to have_many(:responses).through(:requests) }

    it "returns distinct lead providers, ordered by name in ascending order" do
      lead_provider_1 = FactoryBot.create(:lead_provider, name: "B lead provider")
      lead_provider_2 = FactoryBot.create(:lead_provider, name: "A lead provider")
      run = FactoryBot.create(:parity_check_run)
      FactoryBot.create(:parity_check_request, run:, lead_provider: lead_provider_1)
      FactoryBot.create(:parity_check_request, run:, lead_provider: lead_provider_1)
      FactoryBot.create(:parity_check_request, run:, lead_provider: lead_provider_2)

      expect(run.lead_providers).to eq([lead_provider_2, lead_provider_1])
    end

    it "returns distinct endpoints, ordered by path in ascending order" do
      endpoint_1 = FactoryBot.create(:parity_check_endpoint, path: "/b/path")
      endpoint_2 = FactoryBot.create(:parity_check_endpoint, path: "/a/path")
      run = FactoryBot.create(:parity_check_run)
      FactoryBot.create(:parity_check_request, run:, endpoint: endpoint_1)
      FactoryBot.create(:parity_check_request, run:, endpoint: endpoint_1)
      FactoryBot.create(:parity_check_request, run:, endpoint: endpoint_2)

      expect(run.endpoints).to eq([endpoint_2, endpoint_1])
    end

    it "returns responses, ordered by page in ascending order" do
      run = FactoryBot.create(:parity_check_run, :in_progress, requests: [])
      request = FactoryBot.create(:parity_check_request, :in_progress, run:)
      response_1 = FactoryBot.create(:parity_check_response, request:, page: 2)
      response_2 = FactoryBot.create(:parity_check_response, request:, page: 1)

      expect(run.responses).to eq([response_2, response_1])
    end
  end

  describe "defaults" do
    it { is_expected.to have_attributes(mode: "concurrent") }
  end

  describe "after_commit" do
    it "broadcasts the run states" do
      in_progress_run = FactoryBot.create(:parity_check_run, :in_progress)
      FactoryBot.create_list(:parity_check_run, 3, :completed)
      FactoryBot.create_list(:parity_check_run, 2, :pending)

      partial = "migration/parity_checks/runs_sidebar"
      locals = {
        in_progress_run:,
        completed_runs: described_class.completed,
        pending_runs: described_class.pending,
      }
      html = "<div>sidebar content</div>"
      allow(::Migration::ParityChecksController.renderer).to receive(:render).with(partial:, locals:) { html }

      run = FactoryBot.create(:parity_check_run)

      expect(run).to receive(:broadcast_update_to).with(:run_states, html:, target: :run_states).once
      run.touch
    end
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
      subject(:run) { FactoryBot.build(:parity_check_run, :completed, started_at:) }

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

    describe ".completed" do
      subject { described_class.completed }

      it { is_expected.to contain_exactly(completed_run) }

      context "when there are multiple completed runs" do
        let!(:completed_run_oldest) { FactoryBot.create(:parity_check_run, :completed, started_at: completed_run.started_at - 1.day) }
        let!(:completed_run_latest) { FactoryBot.create(:parity_check_run, :completed, started_at: completed_run.started_at + 1.day, completed_at: completed_run.started_at + 2.days) }

        it { is_expected.to eq([completed_run_latest, completed_run, completed_run_oldest]) }
      end
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

      context "when not all requests have been completed" do
        before { FactoryBot.create(:parity_check_request, :in_progress, run:) }

        it { expect { run.complete! }.to raise_error(StateMachines::InvalidTransition, /Not all requests have been completed/) }
      end

      context "when all requests have been completed" do
        before { FactoryBot.create(:parity_check_request, :completed, run:) }

        it { expect { run.complete! }.to change(run, :state).from("in_progress").to("completed") }
      end
    end
  end

  describe "#request_group_names" do
    subject { run.request_group_names }

    let(:requests) do
      [
        "/api/v1/users",
        "/api/v1/statements",
        "/api/v2/statements/:id",
        "/other"
      ].map do |path|
        FactoryBot.create(:parity_check_request, endpoint: FactoryBot.create(:parity_check_endpoint, path:))
      end
    end
    let(:run) { FactoryBot.create(:parity_check_run, requests:) }

    it { is_expected.to eq(%i[miscellaneous statements users]) }
  end

  describe "#match_rate" do
    subject { run.match_rate }

    let(:requests) do
      [
        FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching]),
        FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching different]),
        FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching]),
      ]
    end
    let(:run) { FactoryBot.create(:parity_check_run, :completed, requests:) }

    it { is_expected.to eq(83) }

    context "when there are no requests" do
      let(:requests) { [] }

      it { is_expected.to be_nil }
    end

    context "when there are no responses" do
      let(:run) { FactoryBot.create(:parity_check_run, :in_progress) }

      it { is_expected.to be_nil }
    end
  end

  describe "#progress" do
    subject { run.progress }

    let(:run) { FactoryBot.create(:parity_check_run, request_states:) }

    context "when there are no requests" do
      let(:request_states) { [] }

      it { is_expected.to eq(100) }
    end

    context "when there are no completed requests" do
      let(:request_states) { %i[pending queued in_progress] }

      it { is_expected.to eq(0) }
    end

    context "when there are requests in various states" do
      let(:request_states) { %i[pending pending queued in_progress completed completed completed] }

      it { is_expected.to eq(43) }
    end

    context "when all requests are completed" do
      let(:request_states) { %i[completed completed] }

      it { is_expected.to eq(100) }
    end
  end

  describe "#estimated_completion_at" do
    subject { run.estimated_completion_at }

    let(:started_at) { 1.hour.ago }
    let(:run) { FactoryBot.create(:parity_check_run, state, request_states:, started_at:) }

    context "when the run is in progress" do
      let(:state) { :in_progress }
      let(:request_states) { %i[in_progress in_progress completed completed] }

      it { is_expected.to be_within(1.second).of(started_at + 2.hours) }

      context "when the run has no requests" do
        let(:request_states) { [] }

        it { is_expected.to be_nil }
      end

      context "when no requests have been completed yet" do
        let(:request_states) { %i[pending queued in_progress] }

        it { is_expected.to be_nil }
      end
    end

    context "when the run is not in progress" do
      let(:state) { :completed }
      let(:request_states) { %i[completed completed] }

      it { is_expected.to be_nil }
    end
  end

  describe "#rect_performance_gain_ratio" do
    subject { run.rect_performance_gain_ratio }

    let(:run) { FactoryBot.create(:parity_check_run, requests:) }

    context "when there are no requests" do
      let(:requests) { [] }

      it { is_expected.to be_nil }
    end

    context "when there are requests" do
      let(:requests) { FactoryBot.create_list(:parity_check_request, 2, :completed) }

      context "when the response times are equal" do
        before do
          requests[0].responses.update!(ecf_time_ms: 100, rect_time_ms: 100)
          requests[1].responses.update!(ecf_time_ms: 50, rect_time_ms: 50)
        end

        it { is_expected.to eq(1.0) }
      end

      context "when the RECT response times are faster" do
        before do
          requests[0].responses.update!(ecf_time_ms: 100, rect_time_ms: 80)
          requests[1].responses.update!(ecf_time_ms: 50, rect_time_ms: 10)
        end

        it { is_expected.to eq(3.2) }
      end

      context "when the ECF response times are faster" do
        before do
          requests[0].responses.update!(ecf_time_ms: 50, rect_time_ms: 80)
          requests[1].responses.update!(ecf_time_ms: 15, rect_time_ms: 100)
        end

        it { is_expected.to eq(-4.2) }
      end
    end
  end
end
