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
    it { is_expected.to belong_to(:lead_school) }
    it { is_expected.to have_many(:supported_schools) }

    it { is_expected.to have_one(:legacy_appropriate_body) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:unclaimed_ect_at_school_periods).class_name("ECTAtSchoolPeriod").with_foreign_key(:school_reported_appropriate_body_id) }
  end

  describe "scopes" do
    before do
      FactoryBot.create(:appropriate_body, :national)
      FactoryBot.create(:appropriate_body, :teaching_school_hub)
      FactoryBot.create(:appropriate_body, :teaching_school_hub, :inactive)
      FactoryBot.create(:appropriate_body, :local_authority)
    end

    it "filters by type and activity" do
      expect(described_class.national.count).to be(1)
      expect(described_class.teaching_school_hub.count).to be(2)
      expect(described_class.local_authority.count).to be(1)
      expect(described_class.active.count).to be(2)
      expect(described_class.inactive.count).to be(2)
      expect(described_class.legacy.count).to be(1)
    end
  end

  describe "validations" do
    subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    describe "associated appropriate body" do
      subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body, :active) }

      let(:teaching_school_hub) { FactoryBot.build(:teaching_school_hub) }
      let(:national_body) { FactoryBot.build(:national_body) }

      context "when neither TSH or National Body is associated" do
        it "must have either a teaching school hub or national body" do
          expect(appropriate_body_period).not_to be_valid
          expect(appropriate_body_period.errors[:base]).to include("An Appropriate Body period must be associated with either a Teaching School Hub or a National Body")
          appropriate_body_period.teaching_school_hub = teaching_school_hub
          expect(appropriate_body_period).to be_valid
        end
      end

      context "when both TSH and National Body are associated" do
        before do
          appropriate_body_period.teaching_school_hub = teaching_school_hub
          appropriate_body_period.national_body = national_body
        end

        it "must have either a teaching school hub or national body" do
          expect(appropriate_body_period).not_to be_valid
          expect(appropriate_body_period.errors[:base]).to include("An Appropriate Body period must be associated with either a Teaching School Hub or a National Body")
          appropriate_body_period.national_body = nil
          expect(appropriate_body_period).to be_valid
        end
      end

      # A national body will have a single unending period
      context "when National Body already has a period" do
        subject(:appropriate_body_period) { FactoryBot.create(:appropriate_body, :national) }

        let(:other_appropriate_body_period) { FactoryBot.build(:appropriate_body, :national) }

        before do
          appropriate_body_period.update!(national_body:)
        end

        it "cannot have more" do
          other_appropriate_body_period.national_body = national_body
          expect(other_appropriate_body_period).not_to be_valid
          expect(other_appropriate_body_period.errors[:base]).to include("A National Body can only have a single Appropriate Body period")
        end
      end
    end
  end

  describe "normalizing" do
    subject { FactoryBot.build(:appropriate_body, name: " Some appropriate body ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some appropriate body")
    end
  end
end
