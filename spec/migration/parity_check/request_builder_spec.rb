RSpec.describe ParityCheck::RequestBuilder do
  let(:lead_provider) { FactoryBot.build(:lead_provider) }
  let(:path) { "/test-path" }
  let(:method) { :get }
  let(:options) { { foo: :bar } }
  let(:endpoint) { ParityCheck::Endpoint.new(method:, path:, lead_provider:, options:) }
  let(:instance) { described_class.new(endpoint:) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(endpoint:)
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:lead_provider).to(:endpoint) }
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
      subject { instance.url(app:) }

      let(:app) { :ecf }

      it { is_expected.to eq("#{ecf_url}#{endpoint.path}") }
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
