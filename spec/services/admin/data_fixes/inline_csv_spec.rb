RSpec.describe Admin::DataFixes::InlineCSV do
  subject(:inline_csv) { described_class.new(csv_string:) }

  describe "#parse" do
    subject(:parse) { inline_csv.parse }

    context "when the CSV is missing" do
      let(:csv_string) { "" }

      it { is_expected.to be_falsey }

      it "validates the CSV is present" do
        parse
        expect(inline_csv.errors).to be_added(:csv_string, "CSV can’t be blank")
      end
    end

    context "when the CSV is malformed" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,attributes
          something,1,create,"unterminated,string
        ROWS
      end

      it { is_expected.to be_falsey }

      it "validates the CSV is formatted correctly" do
        parse
        expect(inline_csv.errors).to be_added(:csv_string, "CSV is malformed")
      end
    end

    context "when the CSV has no headers" do
      let(:csv_string) do
        <<~ROWS
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_falsey }

      it "validates the CSV has the correct headers" do
        parse
        expect(inline_csv.errors).to be_added(:csv_string, "CSV has invalid headers")
      end
    end

    context "when the CSV has missing headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_falsey }

      it "validates the CSV has the correct headers" do
        parse
        expect(inline_csv.errors).to be_added(:csv_string, "CSV has invalid headers")
      end
    end

    context "when the CSV has the wrong headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,wrong_header
          something,1,create,"attribute1,value1,attribute2,value2"
          anotherthing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_falsey }

      it "validates the CSV has the correct headers" do
        parse
        expect(inline_csv.errors).to be_added(:csv_string, "CSV has invalid headers")
      end
    end

    context "when the CSV is formatted correctly with the expected headers" do
      let(:csv_string) do
        <<~ROWS
          object_type,object_id,action,attributes
          something,1,create,"attribute1,value1,attribute2,value2"
          another_thing,2,destroy,""
        ROWS
      end

      it { is_expected.to be_truthy }

      it "returns an array of hashes containing data changes" do
        expect(parse).to eq(
          [
            {
              "object_type" => "something",
              "object_id" => "1",
              "action" => "create",
              "attributes" => "attribute1,value1,attribute2,value2"
            },
            {
              "object_type" => "another_thing",
              "object_id" => "2",
              "action" => "destroy",
              "attributes" => ""
            }
          ]
        )
      end
    end
  end
end
