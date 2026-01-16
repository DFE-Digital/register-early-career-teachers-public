class TestController
  include API::ConditionExtractable

  public :extract_conditions
end

RSpec.describe API::ConditionExtractable do
  let(:controller) { TestController.new }

  describe "#extract_conditions" do
    context "with blank input" do
      it { expect(controller.extract_conditions(nil)).to be_nil }
      it { expect(controller.extract_conditions("")).to be_nil }
      it { expect(controller.extract_conditions([])).to be_nil }
    end

    context "with string input" do
      it "splits the string by comma" do
        expect(controller.extract_conditions("a,b,c")).to eq(%w[a b c])
      end
    end

    context "with array input" do
      it "compacts the array" do
        expect(controller.extract_conditions(["a", nil, "b"])).to eq(%w[a b])
      end
    end

    context "with other types" do
      it "passes through unchanged" do
        expect(controller.extract_conditions(123)).to eq(123)
      end
    end

    context "with type: :uuid" do
      let(:valid_uuid) { "550e8400-e29b-41d4-a716-446655440000" }
      let(:another_valid_uuid) { "6ba7b810-9dad-11d1-80b4-00c04fd430c8" }

      it "keeps valid UUIDs" do
        expect(controller.extract_conditions([valid_uuid, another_valid_uuid], type: :uuid)).to eq([valid_uuid, another_valid_uuid])
      end

      it "filters out invalid UUIDs" do
        expect(controller.extract_conditions([valid_uuid, "invalid", "not-a-uuid"], type: :uuid)).to eq([valid_uuid])
      end

      it "works with string input" do
        expect(controller.extract_conditions("#{valid_uuid},invalid,#{another_valid_uuid}", type: :uuid)).to eq([valid_uuid, another_valid_uuid])
      end

      it "returns empty array when all UUIDs are invalid" do
        expect(controller.extract_conditions(["invalid", "not-a-uuid"], type: :uuid)).to eq([])
      end
    end

    context "with type: :integer" do
      it "keeps valid integers" do
        expect(controller.extract_conditions(%w[1 2 3], type: :integer)).to eq(%w[1 2 3])
      end

      it "filters out non-integer values" do
        expect(controller.extract_conditions(%w[1 abc 2 3.5], type: :integer)).to eq(%w[1 2])
      end

      it "works with string input" do
        expect(controller.extract_conditions("1,abc,2", type: :integer)).to eq(%w[1 2])
      end

      it "returns empty array when all values are invalid" do
        expect(controller.extract_conditions(%w[abc def], type: :integer)).to eq([])
      end
    end
  end
end
