RSpec.describe API::Errors::Mapper do
  let(:instance) { described_class.new }

  before { stub_const("#{described_class}::YAML_FILE_PATH", file_fixture("api_error_mappings.yml")) }

  describe "#map_error" do
    subject(:map_error) { instance.map_error(**error) }

    let(:error) { { title: "a title with a rect_term", detail: "a message with a rect_term" } }

    it "maps error keys using the YAML mappings" do
      result = map_error

      expect(result[:title]).to eql("a title with a ecf_term")
      expect(result[:detail]).to eql("a message with a ecf_term")
    end

    context "when there are multiple occurrences of mappable terms" do
      let(:error) { { title: "rect_term and rect_term", detail: "rect_term or rect_term" } }

      it "replaces all occurrences" do
        result = map_error

        expect(result[:title]).to eql("ecf_term and ecf_term")
        expect(result[:detail]).to eql("ecf_term or ecf_term")
      end
    end

    context "when some terms are substrings of other terms" do
      let(:error) { { title: "longer_rect_term", detail: "maps rect_term after longer_rect_term" } }

      it "correctly replaces all terms (prioritising whole terms over substring terms)" do
        result = map_error

        expect(result[:title]).to eql("something_different_in_ecf")
        expect(result[:detail]).to eql("maps ecf_term after something_different_in_ecf")
      end
    end

    context "when the mappings file is missing" do
      before { stub_const("#{described_class}::YAML_FILE_PATH", "non_existent_file.yml") }

      it { expect { map_error }.to raise_error(API::Errors::Mapper::MappingsFileNotFoundError, "Mappings file not found: non_existent_file.yml") }
    end
  end
end
