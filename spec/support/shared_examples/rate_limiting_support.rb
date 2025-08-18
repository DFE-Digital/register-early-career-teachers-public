require "dfe/analytics/rspec/matchers"

RSpec.shared_examples "a rate limited endpoint", :rack_attack do |desc|
  describe desc do
    subject { response }

    let(:limit) { 2 }
    let(:throttle) { Rack::Attack.throttles[desc] }

    before do
      memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rack::Attack.cache).to receive(:store) { memory_store }

      allow(throttle).to receive(:limit) { limit }

      allow(Rails.logger).to receive(:warn)

      freeze_time

      request_count.times { perform_request }
    end

    context "when fewer than rate limit" do
      let(:request_count) { limit - 1 }

      it { is_expected.to have_http_status(:success) }
    end

    context "when more than rate limit" do
      let(:request_count) { limit + 1 }

      it { is_expected.to have_http_status(:too_many_requests) }

      it "logs a warning" do
        expect(Rails.logger).to have_received(:warn).with(
          %r{\[rack-attack\] Throttled request [a-zA-Z0-9]{20} from #{Regexp.escape(request.remote_ip)} to '#{request.path}'}
        )
      end

      it "allows another request when the time restriction has passed" do
        travel(throttle.period + 10.seconds)
        perform_request
        expect(subject).to have_http_status(:success)
      end

      it "allows another request if the condition changes" do
        change_condition
        perform_request
        expect(subject).to have_http_status(:success)
      end

      context "dfe_analytics by default disabled" do
        it { expect { perform_request }.not_to have_sent_analytics_event_types(:persist_api_request) }
      end

      context "dfe_analytics is enabled" do
        before { stub_const('ENV', 'DFE_ANALYTICS_ENABLED' => "true") }

        it { expect { perform_request }.to have_sent_analytics_event_types(:persist_api_request) }

        it "sends correct event type" do
          perform_request

          queue_adapter = ActiveJob::Base.queue_adapter
          job = queue_adapter.enqueued_jobs.find do |job|
            job['job_class'] == 'DfE::Analytics::SendEvents' &&
              job.dig(:args, 0, 0, "event_type") == "persist_api_request"
          end

          expect(job.dig(:args, 0, 0, "response_status")).to eq(429)
          expect(job.dig(:args, 0, 0, "request_path")).to eq(path)
          if path.starts_with?("/api/v3/")
            expect(job.dig(:args, 0, 0, "user_id")).to eq(lead_provider.id)
          end
        end
      end
    end
  end
end
