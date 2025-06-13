RSpec.describe ParityCheck::Configuration do
  let(:enabled) { true }
  let(:tokens) { { "lead_provider_api_id" => "test_token" } }
  let(:ecf_url) { "https://ecf.example.com" }
  let(:rect_url) { "https://rect.example.com" }
  let(:instance) { Class.new { include ParityCheck::Configuration }.new }

  before do
    allow(Rails.application.config).to receive(:parity_check).and_return(enabled:, tokens:, ecf_url:, rect_url:)
  end

  describe "#ensure_parity_check_enabled!" do
    context "when enabled" do
      let(:enabled) { true }

      it { expect { instance.ensure_parity_check_enabled! }.not_to raise_error }
    end

    context "when disabled" do
      let(:enabled) { false }

      it { expect { instance.ensure_parity_check_enabled! }.to raise_error(ParityCheck::Configuration::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end

  describe "#parity_check_tokens" do
    it { expect(instance.parity_check_tokens).to eq(tokens) }
  end

  describe "#parity_check_url" do
    it { expect(instance.parity_check_url(app: :ecf)).to eq(ecf_url) }
    it { expect(instance.parity_check_url(app: :rect)).to eq(rect_url) }
  end
end
