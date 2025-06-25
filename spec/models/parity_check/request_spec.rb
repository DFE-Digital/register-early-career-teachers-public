describe ParityCheck::Request do
  it { expect(described_class).to have_attributes(table_name: "parity_check_requests") }

  describe "associations" do
    it { is_expected.to belong_to(:run) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:endpoint) }
    it { is_expected.to have_many(:responses).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_presence_of(:run) }
    it { is_expected.not_to validate_presence_of(:started_at) }
    it { is_expected.not_to validate_presence_of(:completed_at) }
    it { is_expected.not_to validate_presence_of(:responses) }

    context "when in_progress" do
      subject { FactoryBot.build(:parity_check_request, :in_progress) }

      it { is_expected.to validate_presence_of(:started_at) }
    end

    context "when completed" do
      subject { FactoryBot.build(:parity_check_request, :completed, started_at:) }

      let(:started_at) { Time.current }

      it { is_expected.to validate_presence_of(:completed_at) }
      it { is_expected.to allow_values(started_at, started_at + 1.second).for(:completed_at) }
      it { is_expected.not_to allow_values(nil, started_at - 1.second).for(:completed_at) }
      it { is_expected.to validate_presence_of(:responses) }
    end
  end

  describe "scopes" do
    let!(:pending_get_request) { FactoryBot.create(:parity_check_request, :pending, :get) }
    let!(:queued_get_request) { FactoryBot.create(:parity_check_request, :queued, :get) }
    let!(:in_progress_post_request) { FactoryBot.create(:parity_check_request, :in_progress, :post) }
    let!(:completed_put_request) { FactoryBot.create(:parity_check_request, :completed, :put) }

    describe ".pending" do
      subject { described_class.pending }

      it { is_expected.to contain_exactly(pending_get_request) }
    end

    describe ".completed" do
      subject { described_class.completed }

      it { is_expected.to contain_exactly(completed_put_request) }
    end

    describe ".incomplete" do
      subject { described_class.incomplete }

      it { is_expected.to contain_exactly(pending_get_request, queued_get_request, in_progress_post_request) }
    end

    describe ".queued_or_in_progress" do
      subject { described_class.queued_or_in_progress }

      it { is_expected.to contain_exactly(queued_get_request, in_progress_post_request) }
    end

    describe ".with_method" do
      subject { described_class.with_method(method:) }

      context "when method is :get" do
        let(:method) { :get }

        it { is_expected.to contain_exactly(pending_get_request, queued_get_request) }
      end

      context "when method is :post" do
        let(:method) { :post }

        it { is_expected.to contain_exactly(in_progress_post_request) }
      end

      context "when method is :put" do
        let(:method) { :put }

        it { is_expected.to contain_exactly(completed_put_request) }
      end

      context "when method is [:get, :put]" do
        let(:method) { %i[get put] }

        it { is_expected.to contain_exactly(pending_get_request, queued_get_request, completed_put_request) }
      end
    end

    describe ".with_all_responses_matching" do
      subject { described_class.with_all_responses_matching }

      let!(:request_with_no_responses) { FactoryBot.create(:parity_check_request, :in_progress, response_types: []) }
      let!(:request_with_matching_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching matching]) }
      let!(:request_with_different_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[different]) }
      let!(:request_with_matching_and_different_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching different]) }

      it { expect(subject).to contain_exactly(request_with_matching_responses) }
    end
  end

  describe "state transitions" do
    it { is_expected.to be_pending }

    context "when transitioning from pending to queued" do
      let(:request) { FactoryBot.create(:parity_check_request, :pending) }

      it { expect { request.queue! }.to change(request, :state).from("pending").to("queued") }
    end

    context "when transitioning from queued to in_progress" do
      let(:request) { FactoryBot.create(:parity_check_request, :queued) }

      it { expect { request.start! }.to change(request, :state).from("queued").to("in_progress") }
      it { expect { request.start! }.to change(request, :started_at).from(nil).to(be_within(1.second).of(Time.zone.now)) }
    end

    context "when transitioning from in_progress to completed" do
      let(:request) { FactoryBot.create(:parity_check_request, :in_progress, response_types: %i[different]) }

      it { expect { request.complete! }.to change(request, :state).from("in_progress").to("completed") }
      it { expect { request.complete! }.to change(request, :completed_at).from(nil).to(be_within(1.second).of(Time.zone.now)) }
    end

    context "when attempting an unsupported transition" do
      let(:request) { FactoryBot.create(:parity_check_request, :completed) }

      it { expect { request.queue! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "average response time methods" do
    let(:request) { FactoryBot.build(:parity_check_request) }

    before do
      request.responses = [
        FactoryBot.build(:parity_check_response, ecf_time_ms: 107, rect_time_ms: 105),
        FactoryBot.build(:parity_check_response, ecf_time_ms: 150, rect_time_ms: 250)
      ]
    end

    describe "#average_ecf_response_time_ms" do
      subject { request.average_ecf_response_time_ms }

      it { is_expected.to eq(128.5) }

      context "when there are no responses" do
        before { request.responses = [] }

        it { is_expected.to be_nil }
      end
    end

    describe "#average_rect_response_time_ms" do
      subject { request.average_rect_response_time_ms }

      it { is_expected.to eq(177.5) }

      context "when there are no responses" do
        before { request.responses = [] }

        it { is_expected.to be_nil }
      end
    end
  end
end
