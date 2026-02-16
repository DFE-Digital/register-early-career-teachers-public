describe Migration::ParticipantBand, type: :model do
  let(:instance) { FactoryBot.create(:migration_participant_band) }

  describe "associations" do
    it { is_expected.to belong_to(:call_off_contract) }
  end

  describe "#attributes" do
    subject(:attributes) { instance.attributes }

    it "returns all the band attributes we migrate" do
      expect(attributes.keys).to include(*Migrators::Contract::BAND_ATTRIBUTES)
      expect(attributes.slice(*Migrators::Contract::BAND_ATTRIBUTES)).to all(be_present)
    end
  end
end
