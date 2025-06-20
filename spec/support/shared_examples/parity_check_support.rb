RSpec.shared_examples "client performs requests" do
  let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
  let(:ecf_requests) { requests.select { |r| r.uri.to_s.include?(ecf_url) } }
  let(:rect_requests) { requests.select { |r| r.uri.to_s.include?(rect_url) } }
  let(:ecf_body) { "ecf_body" }
  let(:rect_body) { "rect_body" }
  let(:path_without_query_parameters) do
    # In case the endpoint path has parameters directly in it
    # we strip them out (as we test explicitly for them elsewhere).
    endpoint.path.split("?").first
  end

  before do
    stub_request(endpoint.method, %r{#{ecf_url + path_without_query_parameters}.*}).to_return(status: 200, body: ecf_body)
    stub_request(endpoint.method, %r{#{rect_url + path_without_query_parameters}.*}).to_return(status: 201, body: rect_body)
  end

  it "makes requests to the correct URL for each app" do
    instance.perform_requests {}

    expect(ecf_requests.count).to eq(1)
    expect(rect_requests.count).to eq(1)
  end

  it "makes requests with the correct headers" do
    instance.perform_requests {}

    expect(requests.map(&:headers)).to all include({
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Bearer #{token}",
    })
  end

  it "yields the response of request to the block" do
    instance.perform_requests do |response|
      expect(response).to have_attributes({
        ecf_body:,
        ecf_status_code: 200,
        ecf_time_ms: be >= 0,
        rect_body:,
        rect_status_code: 201,
        rect_time_ms: be >= 0
      })
    end
  end
end

RSpec.shared_examples "client performs requests with body" do
  it "makes requests with the correct body" do
    instance.perform_requests {}

    ecf_body = ecf_requests.first.body
    rect_body = rect_requests.first.body

    expect(ecf_body).to be_present
    expect(rect_body).to be_present

    expect { JSON.parse(ecf_body) }.not_to raise_error
    expect { JSON.parse(rect_body) }.not_to raise_error
  end
end
