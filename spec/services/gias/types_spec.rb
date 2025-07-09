RSpec.describe GIAS::Types do
  describe "ELIGIBLE_TYPES" do
    it "matches the old hardcoded list" do
      expect(described_class::ELIGIBLE_TYPES).to contain_exactly("Academy 16 to 19 sponsor led",
                                                                 "Academy 16-19 converter",
                                                                 "Academy alternative provision converter",
                                                                 "Academy alternative provision sponsor led",
                                                                 "Academy converter",
                                                                 "Academy secure 16 to 19",
                                                                 "Academy special converter",
                                                                 "Academy special sponsor led",
                                                                 "Academy sponsor led",
                                                                 "City technology college",
                                                                 "Community school",
                                                                 "Community special school",
                                                                 "Foundation school",
                                                                 "Foundation special school",
                                                                 "Free schools 16 to 19",
                                                                 "Free schools alternative provision",
                                                                 "Free schools special",
                                                                 "Free schools",
                                                                 "Further education",
                                                                 "Local authority nursery school",
                                                                 "Non-maintained special school",
                                                                 "Pupil referral unit",
                                                                 "Sixth form centres",
                                                                 "Special post 16 institution",
                                                                 "Studio schools",
                                                                 "University technical college",
                                                                 "Voluntary aided school",
                                                                 "Voluntary controlled school")
    end
  end

  describe "CIP_ONLY_TYPES" do
    it "matches the old hardcoded list" do
      expect(described_class::CIP_ONLY_TYPES).to contain_exactly("British schools overseas",
                                                                 "Other independent school",
                                                                 "Other independent special school",
                                                                 "Welsh establishment")
    end
  end

  describe "CIP_ONLY_EXCEPT_WELSH" do
    it "matches the old hardcoded list" do
      expect(described_class::CIP_ONLY_EXCEPT_WELSH).to contain_exactly("British schools overseas",
                                                                        "Other independent school",
                                                                        "Other independent special school")
    end
  end

  describe "INDEPENDENT_SCHOOLS_TYPES" do
    it "matches the old hardcoded list" do
      expect(described_class::INDEPENDENT_SCHOOLS_TYPES).to contain_exactly("Other independent school",
                                                                            "Other independent special school")
    end
  end
end
