RSpec.describe ParityCheck::Endpoint do
  let(:method) { :get }
  let(:path) { "/test-path" }
  let(:options) { { foo: :bar } }
  let(:instance) { described_class.new(method:, path:, options:) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(
      method:,
      path:,
      options:
    )
  end

  describe "#options=" do
    it "sets options to an empty hash if nil is provided" do
      instance.options = nil
      expect(instance.options).to eq({})
    end
  end

  describe "#method=" do
    it "converts the method to a symbol" do
      instance.method = "get"
      expect(instance.method).to eq(:get)
    end
  end
end
