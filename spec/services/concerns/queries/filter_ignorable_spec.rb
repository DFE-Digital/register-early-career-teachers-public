class TestQuery
  include Queries::FilterIgnorable
end

RSpec.describe Queries::FilterIgnorable do
  let(:query) { TestQuery.new }

  describe "#ignore?" do
    it { expect(query).to be_ignore(filter: " ") }
    it { expect(query).to be_ignore(filter: "") }
    it { expect(query).to be_ignore(filter: :ignore) }
    it { expect(query).not_to be_ignore(filter: nil) }
    it { expect(query).not_to be_ignore(filter: "value") }
    it { expect(query).not_to be_ignore(filter: false) }
  end
end
