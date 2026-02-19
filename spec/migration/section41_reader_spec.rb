RSpec.describe Section41Reader do
  subject(:reader) { described_class.new(csv_file: Rails.root.join("spec/fixtures/section41_data.csv")) }

  describe "#section41_approvals" do
    let(:data) { reader.section41_approvals }

    it "returns an array of hashes" do
      expect(data.count).to eq 2
      expect(data.first.class).to eq Hash
    end

    it "has the correct columns" do
      expect(data.first.keys).to match_array %w[la_code est_no urn name source_est_type gias_establishment_type s41_granted s41_revoked]
    end
  end
end
