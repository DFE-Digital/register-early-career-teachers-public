describe User do
  subject(:user) { FactoryBot.build(:user) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%i[admin finance super_admin]).with_message("Must be admin, finance or super_admin") }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:authored_events).inverse_of(:author).class_name('Event') }
  end

  describe 'enums' do
    it 'has a roles enum with admin, finance and superuser' do
      expect(subject).to(
        define_enum_for(:role)
          .with_values({ admin: "admin",
                         super_admin: "super_admin",
                         finance: "finance" })
          .backed_by_column_of_type(:enum)
      )
    end
  end
end
