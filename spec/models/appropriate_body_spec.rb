describe AppropriateBody do
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
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:unclaimed_ect_at_school_periods).class_name("ECTAtSchoolPeriod").with_foreign_key(:school_reported_appropriate_body_id) }
  end

  describe "validations" do
    subject { FactoryBot.build(:appropriate_body) }

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
