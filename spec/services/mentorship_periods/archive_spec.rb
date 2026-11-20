RSpec.describe MentorshipPeriods::Archive do
  describe ".call" do
    let(:mentorship_period) { FactoryBot.create(:mentorship_period) }

    it "archives the mentorship period" do
      described_class.call(mentorship_period)

      expect(mentorship_period.reload).to be_archived
    end
  end
end
