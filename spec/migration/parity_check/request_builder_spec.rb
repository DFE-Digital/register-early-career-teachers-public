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
    let(:tokens) { { lead_provider.api_id => "test_token" } }
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
  end
end
