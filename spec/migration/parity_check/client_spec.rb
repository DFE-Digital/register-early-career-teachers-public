RSpec.describe ParityCheck::Client do
  let(:ecf_url) { "https://ecf.example.com" }
  let(:rect_url) { "https://rect.example.com" }
  let(:endpoint) { build(:parity_check_endpoint) }
  let(:request) { build(:parity_check_request, endpoint:) }
  let(:token) { "test_token" }
  let(:per_page) { ParityCheck::RequestBuilder::PAGINATION_PER_PAGE }
  let(:instance) { described_class.new(request:) }

  before do
    allow(Rails.application.config).to receive(:parity_check).and_return({
      enabled: true,
      ecf_url:,
      rect_url:,
      tokens: { request.lead_provider.ecf_id => token }.to_json,
    })
  end

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "#perform_requests" do
    context "when performing a GET request" do
      let(:endpoint) { build(:parity_check_endpoint, :get) }

      include_examples "client performs requests"
    end

    context "when performing a request with query parameters" do
      let(:endpoint) { build(:parity_check_endpoint, :with_query_parameters) }

      include_examples "client performs requests"

      it "makes requests with the correct query parameters" do
        instance.perform_requests {}

        query_parameters = endpoint.options[:query].to_query
        expect(ecf_requests.first.uri.query).to eq(query_parameters)
        expect(rect_requests.first.uri.query).to eq(query_parameters)
      end
    end

    context "when the path and options contain query parameters and pagination is enabled" do
      let(:endpoint) { build(:parity_check_endpoint, :with_query_parameters_and_pagination, path: "/test-path?path=parameter") }

      include_examples "client performs requests"

      it "makes requests with the correct query parameters" do
        options_query_parameters = endpoint.options[:query]
        path_query_parameters = Addressable::URI.parse(endpoint.path).query_values
        page_query_parameters = { page: { page: 1, per_page: } }
        all_query_parameters = path_query_parameters.merge(options_query_parameters, page_query_parameters).to_query

        instance.perform_requests {}

        expect(ecf_requests.first.uri.query).to eq(all_query_parameters)
        expect(rect_requests.first.uri.query).to eq(all_query_parameters)
      end
    end

    context "when performing a request with pagination" do
      let(:endpoint) { build(:parity_check_endpoint, :with_pagination) }

      include_examples "client performs requests"

      it "makes multiple requests with the correct pagination parameters" do
        full_page_of_data = { data: Array.new(per_page, { key: :value }) }.to_json
        partial_page_of_data = { data: Array.new(per_page / 2, { key: :value }) }.to_json

        stub_request(endpoint.method, %r{#{ecf_url + path_without_query_parameters}.*}).to_return(
          { status: 200, body: full_page_of_data },
          { status: 200, body: partial_page_of_data }
        )

        stub_request(endpoint.method, %r{#{rect_url + path_without_query_parameters}.*}).to_return(
          { status: 201, body: full_page_of_data },
          { status: 200, body: partial_page_of_data }
        )

        yielded_responses = []
        instance.perform_requests { yielded_responses << it }

        expect(yielded_responses.count).to eq(2)

        first_page_query = { page: { page: 1, per_page: } }.to_query
        expect(ecf_requests.first.uri.query).to include(first_page_query)
        expect(rect_requests.first.uri.query).to include(first_page_query)

        second_page_query = { page: { page: 2, per_page: } }.to_query
        expect(ecf_requests.last.uri.query).to include(second_page_query)
        expect(rect_requests.last.uri.query).to include(second_page_query)

        expect(ecf_requests.count).to eq(2)
        expect(rect_requests.count).to eq(2)
      end
    end

    context "when performing a POST request" do
      let(:endpoint) { build(:parity_check_endpoint, :post) }

      include_examples "client performs requests"
      include_examples "client performs requests with body"
    end

    context "when performing a PUT request" do
      let(:endpoint) { build(:parity_check_endpoint, :put) }

      include_examples "client performs requests"
      include_examples "client performs requests with body"
    end
  end

  context "when an unsupported request method is used" do
    let(:endpoint) { build(:parity_check_endpoint, method: :fetch) }

    it "raises an UnsupportedRequestMethodError" do
      expect {
        instance.perform_requests {}
      }.to raise_error(NoMethodError, "undefined method 'fetch' for an instance of Faraday::Connection")
    end
  end
end
