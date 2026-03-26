describe Migration::SchoolMentor do
  describe "relationships" do
    it { is_expected.to belong_to(:participant_profile) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:preferred_identity).class_name("Migration::ParticipantIdentity") }
  end
end
