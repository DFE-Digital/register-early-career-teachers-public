RSpec.describe Migration::TeacherCombinationsExporter do
  subject(:exporter) { described_class.new }

  let!(:combination_1) { FactoryBot.create(:data_migration_teacher_combination) }
  let!(:combination_2) { FactoryBot.create(:data_migration_teacher_combination) }

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

    it "contains the teacher combinations" do
      csv = CSV.parse(csv_output, headers: true)
      expect(csv.length).to eq 2

      csv.each do |row|
        expect(row["trn"]).to be_in [combination_1.trn, combination_2.trn]
      end
    end
  end
end
