class TestQuery
  include QueryOrderable
end

RSpec.describe QueryOrderable do
  let(:query) { TestQuery.new }

  describe "#sort_order" do
    it "returns a formatted sort order relative to the model" do
      sort_order = query.sort_order(sort: "-created_at,updated_at,invalid", model: User, default: { id: :asc })
      expect(sort_order).to eq("users.created_at DESC, users.updated_at ASC")
    end

    it "returns nil when there is no sort" do
      expect(query.sort_order(sort: " ", model: User)).to be_nil
    end

    it "returns the default sort order when there is no sort" do
      default = { created_at: :asc }
      sort_order = query.sort_order(sort: nil, default:, model: User)
      expect(sort_order).to eq(default)
    end
  end
end
