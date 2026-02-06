RSpec.describe Migration::FailedCombinationsExporter do
  subject(:exporter) { described_class.new }

  let!(:combination_1) { FactoryBot.create(:data_migration_failed_combination) }
  let!(:combination_2) { FactoryBot.create(:data_migration_failed_combination) }

  describe "#generate" do
    let!(:csv_output) { exporter.generate_csv }

    it "creates a CSV dataset as a string" do
      expect(csv_output).to be_a String
    end

    it "has the correct headers" do
      headers = exporter.send(:csv_headers)

      csv = CSV.parse(csv_output, headers: true)

      expect(csv.headers).to eq headers
    end

    it "contains the failed combinations" do
      csv = CSV.parse(csv_output, headers: true)
      expect(csv.length).to eq 2

      csv.each do |row|
        expect(row["induction_record_id"]).to be_in [combination_1.induction_record_id, combination_2.induction_record_id]
      end
    end
  end
end
