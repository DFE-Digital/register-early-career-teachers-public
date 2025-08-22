RSpec.describe API::Errors::Response do
  subject { described_class.new(title:, messages:) }

  let(:title) { "StandardError" }
  let(:messages) do
    [
      "Error 1",
      "Error 2",
    ]
  end

  describe "#call" do
    it "returns formatted errors" do
      result = subject.call

      expect(result.size).to be(2)

      expect(result[0][:title]).to eql("StandardError")
      expect(result[0][:detail]).to eql("Error 1")

      expect(result[1][:title]).to eql("StandardError")
      expect(result[1][:detail]).to eql("Error 2")
    end

    context 'when `params` is not an Array' do
      let(:messages) { "Error 1" }

      it "returns formatted errors" do
        result = subject.call

        expect(result.size).to be(1)

        expect(result[0][:title]).to eql("StandardError")
        expect(result[0][:detail]).to eql("Error 1")
      end
    end

    context "when the errors contain RECT terms" do
      before { stub_const("API::Errors::Mapper::YAML_FILE_PATH", file_fixture("api_error_mappings.yml")) }

      let(:title) { "a rect_term error title" }
      let(:messages) do
        [
          "a rect_term message",
          "another rect_term message",
        ]
      end

      it "maps the errors using the YAML mappings" do
        result = subject.call

        expect(result[0][:title]).to eql("a ecf_term error title")
        expect(result[0][:detail]).to eql("a ecf_term message")

        expect(result[1][:title]).to eql("a ecf_term error title")
        expect(result[1][:detail]).to eql("another ecf_term message")
      end
    end
  end

  describe ".from" do
    subject(:response) { described_class.from(service) }

    let(:service) { SchoolPartnerships::Create.new.tap(&:valid?) }

    it "returns a hash with formatted errors" do
      expect(response[:errors]).to include(
        { title: "cohort", detail: "Enter a '#/cohort'." },
        { title: "school_id", detail: "Enter a '#/school_id'." }
      )
    end
  end
end
