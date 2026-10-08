describe AppropriateBodyPeriod do
  describe "enums" do
    it do
      expect(subject).to define_enum_for(:body_type)
                           .with_values({ local_authority: "local_authority",
                                          national: "national",
                                          teaching_school_hub: "teaching_school_hub" })
                           .validating
                           .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:dfe_sign_in_organisation) }
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to belong_to(:provisioning_school) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:oauth_authorizations).class_name("API::OAuth::Authorization").dependent(:destroy) }
    it { is_expected.to have_many(:unclaimed_ect_at_school_periods).class_name("ECTAtSchoolPeriod").with_foreign_key(:school_reported_appropriate_body_id) }
    it { is_expected.to have_many(:region_awards).class_name("Region::Award").dependent(:destroy) }
    it { is_expected.to have_many(:regions).through(:region_awards) }
    it { is_expected.to have_many(:lead_schools).through(:region_awards).source(:school) }
  end

  describe "scopes" do
    before do
      FactoryBot.create(:appropriate_body_period, :national)
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub)
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub, :inactive)
      FactoryBot.create(:appropriate_body_period, :local_authority)
    end

    it "filters by type and activity" do
      expect(described_class.national.count).to be(1)
      expect(described_class.teaching_school_hub.count).to be(2)
      expect(described_class.local_authority.count).to be(1)
      expect(described_class.active.count).to be(2)
      expect(described_class.inactive.count).to be(2)
    end
  end

  describe "predicates" do
    describe "#active?" do
      context "when `dfe_sign_in_organisation_id` is present" do
        subject(:appropriate_body_period) do
          FactoryBot.build_stubbed(
            :appropriate_body_period,
            dfe_sign_in_organisation_id: SecureRandom.uuid
          )
        end

        it { is_expected.to be_active }
      end

      context "when `dfe_sign_in_organisation_id` is missing" do
        subject(:appropriate_body_period) do
          FactoryBot.build_stubbed(
            :appropriate_body_period,
            dfe_sign_in_organisation_id: nil
          )
        end

        it { is_expected.not_to be_active }
      end
    end
  end

  describe "validations", skip: "during data cleanse" do
    subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body_period) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "#name" do
    it "allows duplicate names (temp during data cleanse)" do
      described_class.create!(name: "Shared name")

      expect { described_class.create!(name: "Shared name") }.to change(described_class, :count).by(1)
    end

    it "may be omitted" do
      expect { described_class.create!(name: nil) }.to change(described_class, :count).by(1)
    end
  end

  describe "normalizing" do
    subject { FactoryBot.build(:appropriate_body, name: " Some appropriate body ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some appropriate body")
    end
  end

  describe "lead schools and regions" do
    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
    let(:school) { FactoryBot.create(:school) }
    let(:region) { FactoryBot.create(:region) }
    let(:other_region) { FactoryBot.create(:region) }

    before do
      FactoryBot.create(:region_award, appropriate_body_period:, school:, region:)
      FactoryBot.create(:region_award, appropriate_body_period:, school:, region: other_region)
    end

    it "lists lead schools and regions collapsing multi-region schools" do
      expect(appropriate_body_period.lead_schools).to contain_exactly(school)
      expect(appropriate_body_period.regions).to contain_exactly(region, other_region)
    end
  end
end
