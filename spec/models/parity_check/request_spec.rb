describe ParityCheck::Request do
  it { expect(described_class).to have_attributes(table_name: "parity_check_requests") }

  describe "associations" do
    it { is_expected.to belong_to(:run) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:endpoint) }
    it { is_expected.to have_many(:responses).dependent(:destroy) }
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:description).to(:endpoint) }
    it { is_expected.to delegate_method(:method).to(:endpoint) }
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
    let(:run) { FactoryBot.create(:parity_check_run, :in_progress) }
    let!(:pending_get_request) { FactoryBot.create(:parity_check_request, :pending, :get, run:) }
    let!(:queued_get_request) { FactoryBot.create(:parity_check_request, :queued, :get, run:) }
    let!(:in_progress_post_request) { FactoryBot.create(:parity_check_request, :in_progress, :post, run:) }
    let!(:completed_put_request) { FactoryBot.create(:parity_check_request, :completed, :put, run:) }
    let!(:failed_post_request) { FactoryBot.create(:parity_check_request, :failed, :post, run:) }

    describe ".pending" do
      subject { described_class.pending }

      it { is_expected.to contain_exactly(pending_get_request) }
    end

    describe ".completed" do
      subject { described_class.completed }

      it { is_expected.to contain_exactly(completed_put_request) }
    end

    describe ".failed" do
      subject { described_class.failed }

      it { is_expected.to contain_exactly(failed_post_request) }
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

        it { is_expected.to contain_exactly(in_progress_post_request, failed_post_request) }
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

    describe ".with_lead_provider" do
      subject { described_class.with_lead_provider(lead_provider) }

      let(:lead_provider) { completed_put_request.lead_provider }

      it { is_expected.to contain_exactly(completed_put_request) }
    end

    describe ".with_all_responses_matching" do
      subject { described_class.with_all_responses_matching }

      let(:run) { FactoryBot.create(:parity_check_run, :in_progress) }
      let!(:request_with_no_responses) { FactoryBot.create(:parity_check_request, :in_progress, response_types: [], run:) }
      let!(:request_with_matching_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching matching], run:) }
      let!(:request_with_different_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[different], run:) }
      let!(:request_with_matching_and_different_responses) { FactoryBot.create(:parity_check_request, :completed, response_types: %i[matching different], run:) }

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

      it "broadcasts the run states" do
        expect(request.run).to receive(:broadcast_run_states).once

        request.complete!
      end
    end

    context "when transitioning from in_progress to failed" do
      let(:request) { FactoryBot.create(:parity_check_request, :in_progress) }

      it { expect { request.halt! }.to change(request, :state).from("in_progress").to("failed") }
    end

    context "when attempting an unsupported transition" do
      let(:request) { FactoryBot.create(:parity_check_request, :completed) }

      it { expect { request.queue! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "#rect_performance_gain_ratio" do
    subject { request.rect_performance_gain_ratio }

    let(:request) { FactoryBot.create(:parity_check_request, responses:) }

    context "when there are no responses" do
      let(:responses) { [] }

      it { is_expected.to be_nil }
    end

    context "when there are responses" do
      let(:responses) { FactoryBot.create_list(:parity_check_response, 2) }

      context "when the response times are equal" do
        before do
          responses[0].update!(ecf_time_ms: 100, rect_time_ms: 100)
          responses[1].update!(ecf_time_ms: 50, rect_time_ms: 50)
        end

        it { is_expected.to eq(1.0) }
      end

      context "when the RECT response times are faster" do
        before do
          responses[0].update!(ecf_time_ms: 100, rect_time_ms: 80)
          responses[1].update!(ecf_time_ms: 50, rect_time_ms: 10)
        end

        it { is_expected.to eq(3.2) }
      end

      context "when the ECF response times are faster" do
        before do
          responses[0].update!(ecf_time_ms: 50, rect_time_ms: 80)
          responses[1].update!(ecf_time_ms: 15, rect_time_ms: 100)
        end

        it { is_expected.to eq(-4.2) }
      end
    end
  end

  describe "#match_rate" do
    subject { request.match_rate }

    let(:response_types) { %i[matching matching different] }
    let(:request) { FactoryBot.create(:parity_check_request, :completed, response_types:) }

    it { is_expected.to eq(67) }

    context "when there are no responses" do
      let(:request) { FactoryBot.create(:parity_check_request, :in_progress, response_types: []) }

      it { is_expected.to be_nil }
    end
  end

  describe "#response_body_ids_different?/#response_body_ids_matching?" do
    subject(:request) { FactoryBot.create(:parity_check_request) }

    let(:matching_body) { {data: [{id: 1}, {id: 2}]}.to_json }
    let(:different_body) { {data: [{id: 2}]}.to_json }

    it { is_expected.not_to be_response_body_ids_different }
    it { is_expected.to be_response_body_ids_matching }

    context "when there are ECF responses with different body IDs" do
      before do
        FactoryBot.create(:parity_check_response, ecf_body: matching_body, request:)
        FactoryBot.create(:parity_check_response, ecf_body: different_body, request:)
      end

      it { is_expected.to be_response_body_ids_different }
      it { is_expected.not_to be_response_body_ids_matching }
    end

    context "when there are RECT responses with different body IDs" do
      before do
        FactoryBot.create(:parity_check_response, rect_body: matching_body, request:)
        FactoryBot.create(:parity_check_response, rect_body: different_body, request:)
      end

      it { is_expected.to be_response_body_ids_different }
      it { is_expected.not_to be_response_body_ids_matching }
    end

    context "when there are ECF and RECT responses with matching IDs" do
      before do
        FactoryBot.create(:parity_check_response, ecf_body: matching_body, rect_body: matching_body, request:)
        FactoryBot.create(:parity_check_response, ecf_body: matching_body, rect_body: matching_body, request:)
      end

      it { is_expected.not_to be_response_body_ids_different }
      it { is_expected.to be_response_body_ids_matching }
    end
  end

  describe "#ecf_response_body_ids" do
    subject { request.ecf_response_body_ids }

    let(:request) { FactoryBot.create(:parity_check_request) }

    it { is_expected.to be_empty }

    context "when there are responses" do
      before do
        FactoryBot.create(:parity_check_response, ecf_body: {data: [{id: 1}, {id: 2}]}.to_json, request:)
        FactoryBot.create(:parity_check_response, ecf_body: {data: [{id: 3}]}.to_json, request:)
        FactoryBot.create(:parity_check_response, ecf_body: {data: {id: 4}}.to_json, request:)
      end

      it { is_expected.to contain_exactly(1, 2, 3, 4) }
    end
  end

  describe "#rect_response_body_ids" do
    subject { request.rect_response_body_ids }

    let(:request) { FactoryBot.create(:parity_check_request) }

    it { is_expected.to be_empty }

    context "when there are responses" do
      before do
        FactoryBot.create(:parity_check_response, rect_body: {data: [{id: 1}, {id: 2}]}.to_json, request:)
        FactoryBot.create(:parity_check_response, rect_body: {data: [{id: 3}]}.to_json, request:)
        FactoryBot.create(:parity_check_response, rect_body: {data: {id: 4}}.to_json, request:)
      end

      it { is_expected.to contain_exactly(1, 2, 3, 4) }
    end
  end

  describe "#ecf_only_response_body_ids" do
    subject { request.ecf_only_response_body_ids }

    let(:request) { FactoryBot.create(:parity_check_request) }

    before do
      ecf_body_1 = {data: [{id: 123}, {id: 456}]}.to_json
      rect_body_1 = {data: [{id: 456}]}.to_json
      FactoryBot.create(:parity_check_response, ecf_body: ecf_body_1, rect_body: rect_body_1, request:)

      ecf_body_1 = {data: [{id: 789}]}.to_json
      rect_body_1 = {data: [{id: 111}]}.to_json
      FactoryBot.create(:parity_check_response, ecf_body: ecf_body_1, rect_body: rect_body_1, request:)
    end

    it { is_expected.to contain_exactly(123, 789) }
  end

  describe "#rect_only_body_ids" do
    subject { request.rect_only_response_body_ids }

    let(:request) { FactoryBot.create(:parity_check_request) }

    before do
      ecf_body_1 = {data: [{id: 123}, {id: 456}]}.to_json
      rect_body_1 = {data: [{id: 456}]}.to_json
      FactoryBot.create(:parity_check_response, ecf_body: ecf_body_1, rect_body: rect_body_1, request:)

      ecf_body_1 = {data: [{id: 789}]}.to_json
      rect_body_1 = {data: [{id: 111}]}.to_json
      FactoryBot.create(:parity_check_response, ecf_body: ecf_body_1, rect_body: rect_body_1, request:)
    end

    it { is_expected.to contain_exactly(111) }
  end
end
