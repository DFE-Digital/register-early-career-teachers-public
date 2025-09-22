describe Schools::DecoratedSchool do
  let(:school) { FactoryBot.create(:school) }
  let(:decorated_school) { Schools::DecoratedSchool.new(school) }
  let(:contract_period) { FactoryBot.create(:contract_period) }

  it 'decorates a School' do
    expect(decorated_school.__getobj__).to be_a(School)
  end

  describe '#latest_registration_choices' do
    let(:fake_latest_registration_choices) { double('Schools::LatestRegistrationChoices') }

    before do
      allow(Schools::LatestRegistrationChoices).to receive(:new)
                                                     .with(school: decorated_school, contract_period:)
                                                     .and_return(fake_latest_registration_choices)
    end

    it 'returns a Schools::LatestRegistrationChoices object' do
      expect(decorated_school.latest_registration_choices(contract_period:)).to eql(fake_latest_registration_choices)
    end
  end

  describe '#has_partnership_with?' do
    subject { decorated_school.has_partnership_with?(lead_provider:, contract_period:) }

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:fake_partnership_check) { double('SchoolPartnerships::Search', exists?: true) }

    before do
      allow(SchoolPartnerships::Search).to receive(:new)
                                             .with(lead_provider:, contract_period:)
                                             .and_return(fake_partnership_check)
    end

    it 'creates a SchoolPartnerships::Search and calls #exists?' do
      expect(subject).to be(true)
      expect(fake_partnership_check).to have_received(:exists?).once
      expect(SchoolPartnerships::Search).to have_received(:new).with(lead_provider:, contract_period:)
    end
  end
end
