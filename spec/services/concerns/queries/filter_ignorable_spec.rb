class TestQuery
  include Queries::FilterIgnorable
end

RSpec.describe Queries::FilterIgnorable do
  let(:query) { TestQuery.new }

  describe "#ignore?" do
    it { expect(query).to be_ignore(filter: " ") }
    it { expect(query).to be_ignore(filter: "") }
    it { expect(query).to be_ignore(filter: :ignore) }
    it { expect(query).to be_ignore(filter: []) }
    it { expect(query).not_to be_ignore(filter: nil) }
    it { expect(query).not_to be_ignore(filter: "value") }
    it { expect(query).not_to be_ignore(filter: false) }

    context "when ignore_empty_array is false" do
      it { expect(query).to be_ignore(filter: " ", ignore_empty_array: false) }
      it { expect(query).to be_ignore(filter: "", ignore_empty_array: false) }
      it { expect(query).to be_ignore(filter: :ignore, ignore_empty_array: false) }
      it { expect(query).not_to be_ignore(filter: [], ignore_empty_array: false) }
      it { expect(query).not_to be_ignore(filter: nil, ignore_empty_array: false) }
      it { expect(query).not_to be_ignore(filter: "value", ignore_empty_array: false) }
      it { expect(query).not_to be_ignore(filter: false, ignore_empty_array: false) }
    end
  end
end
