describe Schools::Search do
  let!(:gias_school) { FactoryBot.create(:gias_school, :with_school, name: 'George Washington Carver High School') }
  let(:george_washington) { gias_school.school }

  let!(:other_gias_school) { FactoryBot.create(:gias_school, :with_school, name: 'Immaculate Heart Catholic School') }
  let(:immaculate_heart) { other_gias_school.school }

  it 'finds schools by name' do
    expect(Schools::Search.new('George').search).to include(george_washington)
  end

  it 'finds schools by URN' do
    expect(Schools::Search.new(george_washington.urn).search).to include(george_washington)
  end

  it 'excludes non-matching schools' do
    expect(Schools::Search.new('George').search).not_to include(immaculate_heart)
  end

  it 'retuns all schools when criteria blank' do
    expect(Schools::Search.new('').search).to contain_exactly(george_washington, immaculate_heart)
  end

  it 'retuns schools in name order' do
    a_school = FactoryBot.create(:gias_school, :with_school, name: 'A school')
    z_school = FactoryBot.create(:gias_school, :with_school, name: 'Z school')

    expect(Schools::Search.new('').search.map(&:name)).to eql([
      a_school.name,
      george_washington.name,
      immaculate_heart.name,
      z_school.name,
    ])
  end
end
