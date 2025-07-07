RSpec.describe ParityCheck::RunDispatcher do
  let(:instance) { described_class.new }

  describe "#dispatch" do
    subject(:dispatch) { instance.dispatch }

    it "acquires a lock on the run" do
      expect(ParityCheck::Run).to receive(:with_advisory_lock).with("dispatch_run").and_call_original
      dispatch
    end

    context "when there are pending runs" do
      let!(:pending_runs) { create_list(:parity_check_run, 3, :pending) }
      let(:next_run) { pending_runs.first }

      it "dispatches the next run" do
        request_dispatcher = instance_double(ParityCheck::RequestDispatcher, dispatch: nil)
        allow(ParityCheck::RequestDispatcher).to receive(:new).with(run: next_run).and_return(request_dispatcher)

        expect { dispatch }.to change { next_run.reload.state }.from("pending").to("in_progress")

        expect(request_dispatcher).to have_received(:dispatch)
      end

      context "when there are in-progress runs" do
        before { create(:parity_check_request, :in_progress) }

        it "does not call the request dispatcher" do
          expect { dispatch }.not_to have_enqueued_job(ParityCheckRequestJob)
        end
      end
    end

    context "when there are in-progress/pending runs" do
      before { create(:parity_check_run, :completed) }

      it "does not call the request dispatcher" do
        expect { dispatch }.not_to have_enqueued_job(ParityCheckRequestJob)
      end
    end
  end
end
