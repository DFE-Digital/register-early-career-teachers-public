RSpec.describe API::Errors::Response do
  subject { described_class.new(error:, params:) }

  let(:error) { "StandardError" }
  let(:params) do
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
      let(:params) { "Error 1" }

      it "returns formatted errors" do
        result = subject.call

        expect(result.size).to be(1)

        expect(result[0][:title]).to eql("StandardError")
        expect(result[0][:detail]).to eql("Error 1")
      end
    end
  end
end
