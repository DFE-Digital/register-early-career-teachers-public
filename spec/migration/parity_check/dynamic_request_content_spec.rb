RSpec.describe ParityCheck::DynamicRequestContent do
  let(:lead_provider) { create(:lead_provider) }
  let(:instance) { described_class.new(lead_provider:) }

  describe "#fetch" do
    subject(:fetch) { instance.fetch(identifier) }

    context "when fetching an unrecognized identifier" do
      let(:identifier) { :unrecognized_identifier }

      it { expect { fetch }.to raise_error(described_class::UnrecognizedIdentifierError, "Identifier not recognized: unrecognized_identifier") }
    end

    context "when fetching example_id" do
      let(:identifier) { :example_id }
      let!(:statement) { create(:statement, lead_provider:) }

      # Statement for different lead provider should not be used.
      before { create(:statement) }

      it { is_expected.to eq(statement.api_id) }
    end

    context "when fetching example_body" do
      let(:identifier) { :example_body }

      it "returns the example body" do
        expect(fetch).to eq({
          data: {
            type: "statements",
            attributes: {
              content: "This is an example request body.",
            },
          },
        })
      end
    end
  end
end
