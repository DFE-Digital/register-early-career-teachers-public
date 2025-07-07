describe User do
  subject(:user) { build(:user) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:dfe_roles) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:authored_events).inverse_of(:author).class_name('Event') }
  end
end
