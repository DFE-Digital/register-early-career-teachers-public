RSpec.describe ParityCheck::Client do
  let(:ecf_url) { "https://ecf.example.com" }
  let(:rect_url) { "https://rect.example.com" }
  let(:endpoint) { FactoryBot.build(:parity_check_endpoint) }
  let(:request) { FactoryBot.build(:parity_check_request, endpoint:) }
  let(:token) { "test_token" }
  let(:instance) { described_class.new(request:) }

  before do
    allow(Rails.application.config).to receive(:parity_check).and_return({
      enabled: true,
      ecf_url:,
      rect_url:,
      tokens: { request.lead_provider.api_id => token }.to_json,
    })
  end

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "#perform_requests" do
    context "when performing a GET request" do
      let(:endpoint) { FactoryBot.build(:parity_check_endpoint, :get) }

      include_examples "client performs requests"
    end

    context "when performing a request with query parameters" do
      let(:endpoint) { FactoryBot.build(:parity_check_endpoint, :with_query_parameters) }

      include_examples "client performs requests"

      context "when both the path and options contain query parameters" do
        let(:endpoint) { FactoryBot.build(:parity_check_endpoint, :with_query_parameters, path: "/test-path?path=parameter") }

        include_examples "client performs requests"
      end
    end

    context "when performing a POST request" do
      let(:endpoint) { FactoryBot.build(:parity_check_endpoint, :post) }

      include_examples "client performs requests"
    end

    context "when performing a PUT request" do
      let(:endpoint) { FactoryBot.build(:parity_check_endpoint, :put) }

      include_examples "client performs requests"
    end
  end

  context "when an unsupported request method is used" do
    let(:endpoint) { FactoryBot.build(:parity_check_endpoint, method: :fetch) }

    it "raises an UnsupportedRequestMethodError" do
      expect {
        instance.perform_requests {}
      }.to raise_error(NoMethodError, "undefined method 'fetch' for module HTTParty")
    end
  end
end
