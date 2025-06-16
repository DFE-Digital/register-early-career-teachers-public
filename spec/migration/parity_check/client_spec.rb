RSpec.describe ParityCheck::Client do
  let(:ecf_url) { "https://ecf.example.com:443/test-path" }
  let(:rect_url) { "https://rect.example.com:443/test-path" }
  let(:method) { :get }
  let(:headers) { { "Accept" => "application/json" } }
  let(:request) { FactoryBot.create(:parity_check_request) }
  let(:request_builder) { instance_double(ParityCheck::RequestBuilder, headers:, method:) }
  let(:instance) { described_class.new(request:) }

  before do
    allow(ParityCheck::RequestBuilder).to receive(:new).with(request:).and_return(request_builder)
    allow(request_builder).to receive(:url).with(app: :ecf).and_return(ecf_url)
    allow(request_builder).to receive(:url).with(app: :rect).and_return(rect_url)
  end

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "#perform_requests" do
    let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
    let(:ecf_requests) { requests.select { |r| r.uri.to_s.include?(ecf_url) } }
    let(:rect_requests) { requests.select { |r| r.uri.to_s.include?(rect_url) } }

    before do
      stub_request(method, ecf_url).to_return(status: 200, body: "ecf_body")
      stub_request(method, rect_url).to_return(status: 201, body: "rect_body")
    end

    it "makes requests to the correct URL for each app" do
      instance.perform_requests {}

      expect(ecf_requests.count).to eq(1)
      expect(rect_requests.count).to eq(1)
    end

    it "makes requests with the correct headers" do
      instance.perform_requests {}

      expect(requests.map(&:headers)).to all include(headers)
    end

    it "yields the response of request to the block" do
      instance.perform_requests do |response|
        expect(response).to have_attributes(
          ecf_body: "ecf_body",
          ecf_status_code: 200,
          ecf_time_ms: be >= 0,
          rect_body: "rect_body",
          rect_status_code: 201,
          rect_time_ms: be >= 0
        )
      end
    end

    context "when an unsupported request method is used" do
      let(:method) { :fetch }

      it "raises an UnsupportedRequestMethodError" do
        expect {
          instance.perform_requests {}
        }.to raise_error(NoMethodError, "undefined method 'fetch' for module HTTParty")
      end
    end
  end
end
