RSpec.describe Admin::Finance::SearchDeclarations::ByAPIId do
  describe "#call" do
    let(:api_id) { "9787130d-137d-4ec6-b752-4a30ac241149" }

    let!(:declaration) do
      FactoryBot.create(
        :declaration,
        api_id:
      )
    end

    it "finds a declaration when given an exact api id" do
      result = described_class.new(raw_query: api_id).call

      expect(result).to eq(declaration)
    end

    it "finds a declaration when the api id contains surrounding spaces" do
      result = described_class.new(raw_query: "  #{api_id}  ").call

      expect(result).to eq(declaration)
    end

    it "finds a declaration when pasted in uppercase" do
      result = described_class.new(raw_query: api_id.upcase).call

      expect(result).to eq(declaration)
    end

    it "finds a declaration when pasted with extra characters" do
      result = described_class.new(raw_query: "##{api_id}##").call

      expect(result).to eq(declaration)
    end

    it "returns nil when no matching declaration exists" do
      result = described_class.new(raw_query: "00000000-0000-0000-0000-000000000000").call

      expect(result).to be_nil
    end

    it "returns nil when the query is blank" do
      result = described_class.new(raw_query: "").call

      expect(result).to be_nil
    end

    it "does not remove hyphens from valid uuid format" do
      result = described_class.new(raw_query: api_id).call

      expect(result.api_id).to eq(api_id)
    end
  end
end
