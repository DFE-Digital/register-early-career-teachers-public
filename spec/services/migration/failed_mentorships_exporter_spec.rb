RSpec.describe Migration::FailedMentorshipsExporter do
  subject(:exporter) { described_class.new }

  let!(:mentorship_1) { FactoryBot.create(:data_migration_failed_mentorship) }
  let!(:mentorship_2) { FactoryBot.create(:data_migration_failed_mentorship, :ongoing) }

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

    it "contains the failed mentorships" do
      csv = CSV.parse(csv_output, headers: true)
      expect(csv.length).to eq 2

      csv.each do |row|
        expect(row["ecf_start_induction_record_id"]).to be_in [mentorship_1.ecf_start_induction_record_id, mentorship_2.ecf_start_induction_record_id]
      end
    end
  end
end
