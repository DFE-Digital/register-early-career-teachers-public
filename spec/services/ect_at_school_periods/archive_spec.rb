describe ECTAtSchoolPeriods::Archive do
  describe ".call" do
    let(:ect_at_school_period) { mentorship_period.mentee }

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        ect_at_school_period:
      )
    end

    let!(:mentorship_period) { FactoryBot.create(:mentorship_period) }

    it "archives the period and its training periods without deleting their events" do
      described_class.call(ect_at_school_period)

      expect(ect_at_school_period.reload).to be_archived
      expect(training_period.reload).to be_archived
      expect(mentorship_period.reload).to be_archived
    end
  end
end
