# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe DfESignInOrganisation, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:school) }
    it { is_expected.to have_one(:appropriate_body_period) } # to be removed
    it { is_expected.to have_one(:appropriate_body) }
  end

  describe "validations" do
    subject { FactoryBot.build(:dfe_sign_in_organisation) }

    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "scopes" do
    let!(:nb_1) { FactoryBot.create(:appropriate_body, :with_dsi) }
    let!(:nb_2) { FactoryBot.create(:appropriate_body, :with_dsi) }
    let!(:nb_3) { FactoryBot.create(:appropriate_body, :with_dsi) }
    let!(:school_1) { FactoryBot.create(:school, :with_dsi) }
    let!(:school_2) { FactoryBot.create(:school, :with_dsi) }
    let!(:school_3) { FactoryBot.create(:school, :with_dsi) }

    describe ".national_bodies" do
      let(:scope) { described_class.national_bodies }

      it "lists national body logins" do
        expect(scope).to contain_exactly(
          nb_1.dfe_sign_in_organisation,
          nb_2.dfe_sign_in_organisation,
          nb_3.dfe_sign_in_organisation
        )
        expect(scope).not_to include(
          school_1.dfe_sign_in_organisation,
          school_2.dfe_sign_in_organisation,
          school_3.dfe_sign_in_organisation
        )
      end
    end

    describe ".schools" do
      let(:scope) { described_class.schools }

      it "lists school logins" do
        expect(scope).to contain_exactly(
          school_1.dfe_sign_in_organisation,
          school_2.dfe_sign_in_organisation,
          school_3.dfe_sign_in_organisation
        )
        expect(scope).not_to include(
          nb_1.dfe_sign_in_organisation,
          nb_2.dfe_sign_in_organisation,
          nb_3.dfe_sign_in_organisation
        )
      end
    end
  end

  describe "#last_authenticated_at=" do
    let(:dsi) { FactoryBot.create(:dfe_sign_in_organisation) }

    it "sets first_authenticated_at on first use" do
      expect(dsi.first_authenticated_at).to be_nil
      expect(dsi.last_authenticated_at).to be_nil
      dsi.last_authenticated_at = Date.parse("2024-06-30")
      expect(dsi.first_authenticated_at).not_to eq(Time.zone.now)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
