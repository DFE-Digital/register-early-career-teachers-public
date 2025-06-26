RSpec.describe ParityCheck::SeedEndpoints do
  let(:enabled) { true }
  let(:instance) { described_class.new }

  before { allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: }) }

  describe "#plant!" do
    subject(:plant) { instance.plant! }

    before { stub_const("#{described_class}::YAML_FILE_PATH", file_fixture("parity_check_endpoints.yml")) }

    it "clears existing endpoints" do
      instance.plant!

      existing = ParityCheck::Endpoint.all.to_a

      expect { plant }.not_to change(ParityCheck::Endpoint, :count)

      existing.each { |endpoint| expect { endpoint.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    it "seeds endpoints from the YAML file" do
      expect { plant }.to change(ParityCheck::Endpoint, :count).by(4)

      expect(ParityCheck::Endpoint.all).to include(
        have_attributes(method: :get, path: "/a-path", options: { foo: "bar" }),
        have_attributes(method: :get, path: "/another-path", options: {}),
        have_attributes(method: :get, path: "/another-path", options: { corge: "grault" }),
        have_attributes(method: :post, path: "/yet-another-path", options: { baz: "qux" })
      )
    end

    context "when parity check is disabled" do
      let(:enabled) { false }

      it { expect { plant }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
