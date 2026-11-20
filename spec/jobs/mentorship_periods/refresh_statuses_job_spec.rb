RSpec.describe MentorshipPeriods::RefreshStatusesJob, type: :job do
  subject(:job) { described_class.new }

  let!(:mentorship_periods) { FactoryBot.create_list(:mentorship_period, 2) }

  it "refreshes every mentorship period" do
    mentorship_periods.each do |mentorship_period|
      status_service = instance_double(MentorshipPeriods::MentorshipStatus)
      allow(MentorshipPeriods::MentorshipStatus).to receive(:new).with(mentorship_period:).and_return(status_service)
      expect(status_service).to receive(:refresh!)
    end

    job.perform
  end
end
