RSpec.describe AppropriateBody, type: :model do
  subject(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "associations" do
    it { is_expected.to belong_to(:dfe_sign_in_organisation) }

    it { is_expected.to have_many(:appropriate_body_periods) }
    it { is_expected.to have_many(:regions) }
  end

  describe "scopes" do
    let!(:istip) { FactoryBot.create(:appropriate_body, :istip) }
    let!(:esp) { FactoryBot.create(:appropriate_body, :esp) }
    let!(:tsh_1) { FactoryBot.create(:appropriate_body) }
    let!(:tsh_2) { FactoryBot.create(:appropriate_body) }

    describe ".national" do
      it { expect(described_class.national).to contain_exactly(istip, esp) }
    end

    describe ".regional" do
      it { expect(described_class.regional).to contain_exactly(tsh_1, tsh_2) }
    end
  end

  describe "validations" do
    subject { FactoryBot.build(:appropriate_body) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it { is_expected.to validate_presence_of(:dfe_sign_in_organisation) }
    it { is_expected.to validate_uniqueness_of(:dfe_sign_in_organisation) }
  end

  describe "#appropriate_body_periods" do
    it "can have multiple concurrent appropriate body periods" do
      FactoryBot.create_list(:appropriate_body_period, 9, appropriate_body:)
      expect(appropriate_body.appropriate_body_periods.count).to eq(9)
    end
  end

  describe "#districts" do
    before do
      FactoryBot.create_list(:region, 3, appropriate_body:)
    end

    it { expect(appropriate_body.districts).not_to be_empty }
  end

  describe "#login_school" do
    context "with a DfE Sign-In URN" do
      subject(:appropriate_body) { FactoryBot.create(:appropriate_body, dfe_sign_in_organisation:) }

      let(:school) { FactoryBot.create(:school) }
      let(:dfe_sign_in_organisation) { FactoryBot.create(:dfe_sign_in_organisation, urn: school.urn) }

      it { expect(appropriate_body.login_school.name).to eq(school.name) }
    end

    context "without a DfE Sign-In URN" do
      before do
        FactoryBot.create(:dfe_sign_in_organisation, appropriate_body:)
      end

      it { expect(appropriate_body.login_school).to be_nil }
    end
  end

  describe "#national?" do
    subject { FactoryBot.build(:appropriate_body, :istip) }

    it { is_expected.to be_national }
    it { is_expected.not_to be_teaching_school_hub }
  end

  describe "#teaching_school_hub?" do
    subject { FactoryBot.build(:appropriate_body) }

    it { is_expected.to be_teaching_school_hub }
    it { is_expected.not_to be_national }
  end
end
