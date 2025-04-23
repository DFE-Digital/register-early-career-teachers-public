describe ActiveLeadProvider do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:registration_period_id).with_message('Choose a registration period') }
    it { is_expected.to validate_presence_of(:lead_provider_id).with_message('Choose a lead provider') }

    it 'validates registration period and lead provider are unique in combination' do
      alp1 = FactoryBot.create(:active_lead_provider)
      alp2 = alp1.dup

      expect(alp2).to be_invalid
      expect(alp2.errors.messages[:registration_period_id]).to include('Registration period and lead provider must be unique')
    end
  end
end
