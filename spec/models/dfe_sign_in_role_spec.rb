RSpec.describe DfESignInRole do
  subject { FactoryBot.build(:dfe_sign_in_role) }

  describe "db indexes" do
    it { is_expected.to have_db_index(:code).unique }
    it { is_expected.to have_db_index(:dfe_sign_in_role_id).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:dfe_sign_in_role_id) }
    it { is_expected.to validate_uniqueness_of(:dfe_sign_in_role_id) }

    it { is_expected.to allow_values(*described_class.codes.keys).for(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end
end
