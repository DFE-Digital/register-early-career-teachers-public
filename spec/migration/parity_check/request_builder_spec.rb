RSpec.describe ParityCheck::RequestBuilder do
  let(:lead_provider) { request.lead_provider }
  let(:path) { "/test-path" }
  let(:method) { :get }
  let(:options) { { foo: :bar } }
  let(:endpoint) { ParityCheck::Endpoint.new(method:, path:, options:) }
  let(:request) { FactoryBot.create(:parity_check_request, endpoint:) }
  let(:instance) { described_class.new(request:) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:lead_provider).to(:request) }
    it { is_expected.to delegate_method(:endpoint).to(:request) }

    it { is_expected.to delegate_method(:method).to(:endpoint) }
    it { is_expected.to delegate_method(:path).to(:endpoint) }
    it { is_expected.to delegate_method(:options).to(:endpoint) }
  end

  describe "instance methods" do
    let(:tokens) { { lead_provider.ecf_id => "test_token" } }
    let(:ecf_url) { "https://ecf.example.com" }
    let(:rect_url) { "https://rect.example.com" }

    before do
      allow(Rails.application.config).to receive(:parity_check) do
        {
          enabled: true,
          tokens: tokens.to_json,
          ecf_url:,
          rect_url:,
        }
      end
    end

    describe "#url" do
      subject(:url) { instance.url(app:) }

      let(:app) { :ecf }

      it { is_expected.to eq("#{ecf_url}#{endpoint.path}") }

      context "when the path contains an ID but the options do not specify which one" do
        let(:path) { "/test-path/:id" }

        it { expect { url }.to raise_error(described_class::IDOptionMissingError, "Path contains ID, but options[:id] is missing") }
      end

      context "when the path contains an ID but the options[:id] method is missing" do
        let(:path) { "/test-path/:id" }
        let(:options) { { id: :unrecognized_id } }

        it { expect { url }.to raise_error(described_class::UnrecognizedPathIdError, "Method missing for path ID: unrecognized_id") }
      end

      context "when the path contains a statement_id" do
        let(:path) { "/test-path/:id" }
        let(:options) { { id: :statement_id } }
        let!(:statement) { FactoryBot.create(:statement, lead_provider:) }

        # Statement for different lead provider should not be used.
        before { FactoryBot.create(:statement) }

        it { is_expected.to eq("#{ecf_url}/test-path/#{statement.api_id}") }
      end
    end

    describe "#headers" do
      subject { instance.headers }

      it "returns the correct headers" do
        expect(instance.headers).to eq(
          "Authorization" => "Bearer test_token",
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        )
      end
    end

    describe "#body" do
      subject(:body) { instance.body }

      context "when the body contains an example_statement_body" do
        let(:options) { { body: :example_statement_body } }

        it "returns the example statement body JSON encoded" do
          expect(body).to eq({
            data: {
              type: "statements",
              attributes: {
                content: "This is an example request body.",
              },
            },
          }.to_json)
        end
      end

      context "when the options do not specify a body" do
        let(:options) { {} }

        it { expect(body).to be_nil }
      end

      context "when the options[:body] method is missing" do
        let(:options) { { body: :unrecognized_body } }

        it { expect { body }.to raise_error(described_class::UnrecognizedRequestBodyError, "Method missing for body: unrecognized_body") }
      end
    end

    describe "#query" do
      subject(:query) { instance.query }

      context "when the query is a hash" do
        let(:options) { { query: { filter: { cohort: 2022 } } } }

        it { is_expected.to eq(options[:query]) }
      end

      context "when the query is not a hash" do
        let(:options) { { query: "filter=test" } }

        it { expect { query }.to raise_error(described_class::UnrecognizedQueryError, "Query must be a Hash: filter=test") }
      end
    end
  end
end
