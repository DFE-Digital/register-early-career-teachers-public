describe Migration::MentorCallOffContract, type: :model do
  let(:cpd_lead_provider) { FactoryBot.create(:migration_cpd_lead_provider) }
  let(:instance) { FactoryBot.create(:migration_mentor_call_off_contract, lead_provider: cpd_lead_provider.lead_provider) }

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:cohort) }
  end

  describe "#attributes" do
    subject(:attributes) { instance.attributes }

    it "returns all the flat rate fee structure attributes we migrate" do
      expect(attributes.keys).to include(*Migrators::Contract::FLAT_RATE_FEE_STRUCTURE_ATTRIBUTES)
      expect(attributes.slice(*Migrators::Contract::FLAT_RATE_FEE_STRUCTURE_ATTRIBUTES)).to all(be_present)
    end
  end
end
