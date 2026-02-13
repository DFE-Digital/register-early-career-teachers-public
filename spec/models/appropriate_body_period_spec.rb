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

    it { is_expected.to have_one(:legacy_appropriate_body) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:unclaimed_ect_at_school_periods).class_name("ECTAtSchoolPeriod").with_foreign_key(:school_reported_appropriate_body_id) }
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
      expect(described_class.legacy.count).to be(1)
      expect(described_class.active.count).to be(2)
      expect(described_class.inactive.count).to be(2)
    end
  end

  describe "validations" do
    subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body_period) }

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "normalizing" do
    subject { FactoryBot.build(:appropriate_body, name: " Some appropriate body ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some appropriate body")
    end
  end
end
