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
    it { is_expected.not_to allow_values([], [{ foo: :bar }]).for(:options).with_message("Options must be a hash") }

    it "validates that the path does not contain query parameters" do
      instance = FactoryBot.build(:parity_check_endpoint, path: "/a/path?with=query")
      expect(instance).not_to be_valid
      expect(instance.errors[:path]).to include("Path should not contain query parameters; use options[:query] instead.")
    end
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

  describe "#description" do
    subject { instance.description }

    let(:options) { {} }
    let(:instance) { FactoryBot.build(:parity_check_endpoint, method: :get, path: "/a/path", options:) }

    it { is_expected.to eq("GET /a/path") }

    context "when pagination is enabled" do
      let(:options) { { paginate: true, } }

      it { is_expected.to eq("GET /a/path (all pages)") }
    end

    context "when query parameters are specified" do
      let(:options) { { query: { filter: { cohort: 2022, active: true } }, } }

      it { is_expected.to eq("GET /a/path?filter[active]=true&filter[cohort]=2022") }
    end

    context "when pagination is enabled and query parameters are specified" do
      let(:options) { { paginate: true, query: { filter: { cohort: 2022, active: true } }, } }

      it { is_expected.to eq("GET /a/path?filter[active]=true&filter[cohort]=2022 (all pages)") }
    end
  end

  describe "#group_name" do
    subject { described_class.new(path:).group_name }

    context "when the path matches the expected format" do
      let(:path) { "/api/v3/statements" }

      it { is_expected.to eq(:statements) }
    end

    context "when the path matches the expected format (with query parameters)" do
      let(:path) { "/api/v3/users?query=param" }

      it { is_expected.to eq(:users) }
    end

    context "when the path matches the expected format (nested path)" do
      let(:path) { "/api/v3/users/create" }

      it { is_expected.to eq(:users) }
    end

    context "when the path does not match the expected format" do
      let(:path) { "/some/other/path" }

      it { is_expected.to eq(:miscellaneous) }
    end
  end
end
