RSpec.describe Migrators::LeadProvider do
  subject(:migrator) { described_class.new(worker: 0) }

  let!(:ecf_lead_provider) { FactoryBot.create(:ecf_lead_provider) }

  describe ".record_count" do
    it "returns the number of LeadProvider records in the ECF database" do
      expect(described_class.record_count).to eq 1
    end
  end

  describe ".model" do
    it "returns :lead_provider" do
      expect(described_class.model).to eq :lead_provider
    end
  end

  describe ".lead_providers" do
    it "returns all LeadProvider records in the ECF database" do
      expect(described_class.lead_providers).to eq [ecf_lead_provider]
    end
  end

  describe ".records_per_worker" do
    it "returns the worker batch size for lead_providers" do
      expect(described_class.records_per_worker).to eq 5_000
    end
  end

  describe ".dependencies" do
    it "returns a list of migrators that must be run before this one" do
      expect(described_class.dependencies).to eq []
    end
  end

  describe "#migrate!" do
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :lead_provider) }

    it 'creates a record in the ecf2 database' do
      expect {
        migrator.migrate!
      }.to change(::LeadProvider, :count).by(1)
    end

    it "populates the ecf2 model correctly" do
      migrator.migrate!
      expect(::LeadProvider.first.name).to eq ecf_lead_provider.name
    end
  end
end
