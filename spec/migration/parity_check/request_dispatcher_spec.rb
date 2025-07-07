RSpec.describe ParityCheck::RequestDispatcher do
  let(:mode) { :concurrent }
  let(:run) { create(:parity_check_run, :in_progress, mode) }
  let(:instance) { described_class.new(run:) }
  let(:run_dispatcher) { instance_double(ParityCheck::RunDispatcher, dispatch: nil) }

  before { allow(ParityCheck::RunDispatcher).to receive(:new).and_return(run_dispatcher) }

  describe "attributes" do
    it { expect(instance).to have_attributes(run:) }
  end

  describe "#dispatch" do
    subject(:dispatch) { instance.dispatch }

    it "acquires a lock on the run" do
      expect(ParityCheck::Run).to receive(:with_advisory_lock).with(run.id).and_call_original
      dispatch
    end

    describe "request dispatch order" do
      let!(:pending_get_request) { create(:parity_check_request, :pending, :get, run:) }
      let!(:pending_post_request) { create(:parity_check_request, :pending, :post, run:) }
      let!(:pending_put_request) { create(:parity_check_request, :pending, :put, run:) }

      it "dispatches the get requests first" do
        expect { dispatch }.to change { pending_get_request.reload.state }.from("pending").to("queued")
        expect(ParityCheckRequestJob).to have_been_enqueued.once.with(request_id: pending_get_request.id)
      end

      it "dispatches the post requests when all get requests are completed" do
        %i[queue! start! complete!].each do
          pending_get_request.responses << create(:parity_check_response, :matching)
          pending_get_request.send(it)
          # We complete the put request as it has the same priority and
          # we want to isolate the post request in this test.
          pending_put_request.responses << create(:parity_check_response, :matching)
          pending_put_request.send(it)
        end

        expect { dispatch }.to change { pending_post_request.reload.state }.from("pending").to("queued")
        expect(ParityCheckRequestJob).to have_been_enqueued.once.with(request_id: pending_post_request.id)
      end

      it "dispatches the put requests when all get requests are completed" do
        %i[queue! start! complete!].each do
          pending_get_request.send(it)
          pending_get_request.responses << create(:parity_check_response, :matching)
          # We complete the post request as it has the same priority and
          # we want to isolate the put request in this test.
          pending_post_request.responses << create(:parity_check_response, :matching)
          pending_post_request.send(it)
        end

        expect { dispatch }.to change { pending_put_request.reload.state }.from("pending").to("queued")
        expect(ParityCheckRequestJob).to have_been_enqueued.once.with(request_id: pending_put_request.id)
      end
    end

    describe "request dispatch concurrency" do
      before do
        stub_const("#{described_class}::REQUEST_PRIORITY_MODE", {
          %i[get] => { concurrent: get_concurrency },
          %i[post put] => { concurrent: post_put_concurrency }
        })
      end

      let(:get_concurrency) { 3 }
      let(:post_put_concurrency) { 1 }

      it "dispatches the correct number of get requests" do
        get_requests = create_list(:parity_check_request, get_concurrency + 1, :pending, :get, run:)

        expect { dispatch }.to have_enqueued_job(ParityCheckRequestJob).exactly(get_concurrency).times

        queued_requests = get_requests.map(&:reload).select(&:queued?)
        expect(queued_requests.size).to eq(get_concurrency)
      end

      it "dispatches the correct number of post/put requests" do
        post_requests = create_list(:parity_check_request, post_put_concurrency, :pending, :post, run:)
        put_requests = create_list(:parity_check_request, post_put_concurrency, :pending, :put, run:)
        post_put_requests = post_requests + put_requests

        expect { dispatch }.to have_enqueued_job(ParityCheckRequestJob).exactly(post_put_concurrency).times

        queued_requests = post_put_requests.map(&:reload).select(&:queued?)
        expect(queued_requests.size).to eq(post_put_concurrency)
      end
    end

    describe "run mode handling" do
      before { create_list(:parity_check_request, 3, :pending, :get, run:) }

      context "when concurrent" do
        let(:mode) { :concurrent }

        it { expect { dispatch }.to have_enqueued_job(ParityCheckRequestJob).at_least(:once) }
      end

      context "when sequential" do
        let(:mode) { :sequential }

        it { expect { dispatch }.to have_enqueued_job(ParityCheckRequestJob).once }
      end

      context "when mode is not recognised" do
        before { run.mode = :parallel }

        it { expect { dispatch }.to raise_error(ParityCheck::RequestDispatcher::RunModeError, "Run mode not recognized: parallel") }
      end
    end

    context "when there are pending requests" do
      before { create(:parity_check_request, :pending, run:) }

      it "does not complete the run" do
        expect { dispatch }.not_to(change { run.reload.state })
      end

      it "does not dispatch another run" do
        dispatch
        expect(run_dispatcher).not_to have_received(:dispatch)
      end

      %i[queued in_progress].each do |state|
        context "when there are #{state} requests" do
          before { create(:parity_check_request, state, run:) }

          it "does not dispatch any requests" do
            expect { dispatch }.not_to have_enqueued_job(ParityCheckRequestJob)
          end

          it "does not complete the run" do
            expect { dispatch }.not_to change(run, :completed_at)
          end
        end
      end
    end

    context "when there are no pending/queued/in-progress requests" do
      before { create(:parity_check_request, :completed, run:) }

      it "completes the run" do
        expect { dispatch }.to change { run.reload.state }.from("in_progress").to("completed")
      end

      it "dispatches the next run" do
        dispatch
        expect(run_dispatcher).to have_received(:dispatch)
      end
    end
  end
end
