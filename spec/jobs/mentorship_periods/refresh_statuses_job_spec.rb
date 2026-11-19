RSpec.describe MentorshipPeriods::RefreshStatusesJob, type: :job do
  subject(:job) { described_class.new }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school: mentee.school) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, school: mentor.school, lead_provider:) }

  before { FactoryBot.create(:training_period, :for_ect, ect_at_school_period: mentee, school_partnership:) }

  it "creates a mentorship status if none exists" do
    expect { job.perform }.to change { mentorship_period.lead_provider_mentorship_statuses.count }.by(1)

    mentorship_statuses = mentorship_period.lead_provider_mentorship_statuses
    expect(mentorship_statuses.pluck(:lead_provider_id)).to contain_exactly(lead_provider.id)
  end

  it "persists a changed status and reason" do
    job.perform

    mentorship_period.update!(finished_on: Date.current)
    mentorship_status = mentorship_period.lead_provider_mentorship_statuses.sole

    expect { job.perform }.to change { mentorship_status.reload.slice(:status, :reason) }
      .to({ status: "no-access-required", reason: "mentorship-expired" })
  end
end
