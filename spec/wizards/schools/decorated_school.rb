describe Schools::DecoratedSchool do
  let(:school) { FactoryBot.create(:school) }

  subject { Schools::DecoratedSchool.new(school) }

  it 'decorates a School' do
    expect(subject.__getobj__).to be_a(School)
  end

  describe '#latest_registration_choices' do
  end
end
