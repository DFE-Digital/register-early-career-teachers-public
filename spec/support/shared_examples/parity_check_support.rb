RSpec.shared_examples "completable validations" do
  context "when completed_at is set" do
    subject { described_class.new(completed_at: 1.day.ago) }

    it { is_expected.to validate_presence_of(:started_at) }
  end

  describe "completed_at" do
    subject { instance.errors[:completed_at] }

    let(:instance) { described_class.new(started_at:, completed_at:) }
    let(:started_at) { Time.current }

    before { instance.validate }

    context "when completed_at is not set" do
      let(:completed_at) { nil }

      it { is_expected.to be_empty }
    end

    context "when completed_at is equal to started_at" do
      let(:completed_at) { started_at }

      it { is_expected.to be_empty }
    end

    context "when completed_at is greater than started_at" do
      let(:completed_at) { started_at + 1.hour }

      it { is_expected.to be_empty }
    end

    context "when completed_at is before started_at" do
      let(:completed_at) { started_at - 1.hour }

      it { is_expected.to be_present }
    end
  end
end

RSpec.shared_examples "client performs requests" do
  let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
  let(:ecf_requests) { requests.select { |r| r.uri.to_s.include?(ecf_url) } }
  let(:rect_requests) { requests.select { |r| r.uri.to_s.include?(rect_url) } }

  before do
    # In case the endpoint path has parameters directly in it
    # we strip them out (as we test explicitly for them elsewhere).
    path_without_query_parameters = endpoint.path.split("?").first

    stub_request(endpoint.method, %r{#{ecf_url + path_without_query_parameters}.*}).to_return(status: 200, body: "ecf_body")
    stub_request(endpoint.method, %r{#{rect_url + path_without_query_parameters}.*}).to_return(status: 201, body: "rect_body")
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

  it "makes requests with the correct query parameters" do
    options_query_parameters = endpoint.options[:query] || {}
    path_query_parameters = Addressable::URI.parse(endpoint.path).query_values || {}
    all_query_parameters = path_query_parameters.merge(options_query_parameters).to_query.presence

    if all_query_parameters
      instance.perform_requests {}

      expect(ecf_requests.first.uri.query).to eq(all_query_parameters)
      expect(rect_requests.first.uri.query).to eq(all_query_parameters)
    end
  end

  it "makes requests with the correct body" do
    body = endpoint.options[:body]

    if body
      instance.perform_requests {}

      ecf_body = ecf_requests.first.body
      rect_body = rect_requests.first.body

      expect(ecf_body).to be_present
      expect(rect_body).to be_present

      expect { JSON.parse(ecf_body) }.not_to raise_error
      expect { JSON.parse(rect_body) }.not_to raise_error
    end
  end

  it "yields the response of request to the block" do
    instance.perform_requests do |response|
      expect(response).to have_attributes({
        ecf_body: "ecf_body",
        ecf_status_code: 200,
        ecf_time_ms: be >= 0,
        rect_body: "rect_body",
        rect_status_code: 201,
        rect_time_ms: be >= 0
      })
    end
  end
end
