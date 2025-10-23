RSpec.describe Migration::InductionRecordExporter do
  subject(:exporter) { described_class.new }

  describe "#generate_csv" do
    let!(:induction_record_1) { FactoryBot.create(:migration_induction_record) }
    let!(:induction_record_2) { FactoryBot.create(:migration_induction_record) }
    let!(:csv_output) { exporter.generate_csv }

    it "creates a CSV dataset as a string" do
      expect(csv_output).to be_a String
    end

    it "has the correct headers" do
      headers = exporter.send(:csv_headers)

      csv = CSV.parse(csv_output, headers: true)

      expect(csv.headers).to eq headers
    end

    it "contains the induction records" do
      csv = CSV.parse(csv_output, headers: true)
      expect(csv.length).to eq 2

      csv.each do |row|
        expect(row["induction_record_id"]).to be_in [induction_record_1.id, induction_record_2.id]
      end
    end
  end
end
