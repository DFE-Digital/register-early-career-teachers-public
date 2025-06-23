describe ParityCheck::Endpoint do
  it { expect(described_class).to have_attributes(table_name: "parity_check_endpoints") }

  describe "associations" do
    it { is_expected.to have_many(:requests) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:method) }
    it { is_expected.to validate_inclusion_of(:method).in_array(%w[get post put]) }
    it { is_expected.to allow_values({}, { foo: "bar" }).for(:options) }
    it { is_expected.not_to allow_values([], [{ foo: :bar }]).for(:options) }
  end

  describe "#method" do
    subject { described_class.new(method: "get").method }

    it { is_expected.to eq(:get) }
  end

  describe "#options" do
    subject { described_class.new(options:).options }

    let(:options) { { "foo" => "bar", "nested" => { "key" => "value" } } }

    it { is_expected.to eq(options.deep_symbolize_keys) }
  end

  describe "#options=" do
    it "sets options to an empty hash if nil" do
      endpoint = described_class.new
      endpoint.options = nil
      expect(endpoint.options).to eq({})
    end
  end
end
