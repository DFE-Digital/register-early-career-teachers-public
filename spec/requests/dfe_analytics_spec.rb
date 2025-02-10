require "rails_helper"
require "dfe/analytics/rspec/matchers"

RSpec.describe "DfE Analytics", type: :request do
  before do
    stub_const('ENV', 'DFE_ANALYTICS_ENABLED' => env_var_value)
  end

  context "when disabled" do
    before { FactoryBot.create(:teacher) }

    context "implicitly" do
      let(:env_var_value) { nil }

      it "does not send DFE Analytics entity events" do
        expect(:create_entity).not_to have_been_enqueued_as_analytics_events
      end
    end

    context "explicitly" do
      let(:env_var_value) { "false" }

      it "does not send DFE Analytics entity events" do
        expect(:create_entity).not_to have_been_enqueued_as_analytics_events
      end
    end
  end

  context "when enabled" do
    let(:env_var_value) { "true" }

    it "sends DFE Analytics web request event" do
      expect { get root_path }.to have_sent_analytics_event_types(:web_request)
    end

    it "sends DFE Analytics entity events" do
      FactoryBot.create(:teacher)
      expect(:create_entity).to have_been_enqueued_as_analytics_events
    end

    it "does not send a web request event for GET /healthcheck" do
      expect { get '/healthcheck' }.not_to have_sent_analytics_event_types(:web_request)
    end
  end
end
