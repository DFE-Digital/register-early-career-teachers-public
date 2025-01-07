describe School do
  describe 'associations' do
    it { is_expected.to belong_to(:gias_school).class_name('GIAS::School').with_foreign_key(:urn).inverse_of(:school) }
    it { is_expected.to have_many(:current_mentor_periods).conditions(finished_on: nil).class_name('MentorAtSchoolPeriod') }
    it { is_expected.to have_many(:ect_at_school_periods).inverse_of(:school) }
    it { is_expected.to have_many(:ect_teachers).through(:ect_at_school_periods).source(:teacher) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:mentor_at_school_periods).inverse_of(:school) }
    it { is_expected.to have_many(:mentor_teachers).through(:mentor_at_school_periods).source(:teacher) }
  end

  describe 'validations' do
    subject { FactoryBot.build(:school) }

    it { is_expected.to validate_presence_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:urn) }
  end

  describe '#current_mentor_period' do
    let(:school) { FactoryBot.create(:school) }
    let!(:active_mentor_periods) { FactoryBot.create_list(:mentor_at_school_period, 2, :active, school:) }
    let!(:past_mentor_periods) { FactoryBot.create_list(:mentor_at_school_period, 2, school:) }
    let(:trn) { active_mentor_periods.first.teacher.trn }

    it 'returns only the ongoing mentor period for the teacher with the given trn' do
      expect(school.current_mentor_period(trn:)).to eq(active_mentor_periods.first)
    end
  end
end
