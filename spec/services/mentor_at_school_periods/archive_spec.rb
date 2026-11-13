describe MentorAtSchoolPeriods::Archive do
  let!(:mentor_at_school_period) { mentorship_period.mentor }
  let!(:training_period) do
    FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:)
  end
  let!(:mentorship_period) do
    FactoryBot.create(:mentorship_period)
  end

  describe ".call" do
    it "archives the period and preserves its events" do
      described_class.call(mentor_at_school_period)

      expect(mentor_at_school_period.reload).to be_archived
      expect(training_period.reload).to be_archived
      expect(mentorship_period.reload).to be_archived
    end
  end
end
