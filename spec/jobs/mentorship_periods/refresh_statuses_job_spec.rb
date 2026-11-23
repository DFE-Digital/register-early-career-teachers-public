RSpec.describe MentorshipPeriods::RefreshStatusesJob, type: :job do
  subject(:job) { described_class.new }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school: mentee.school) }
  let(:mentorship_period) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:) }
  let!(:mentorship_status) { FactoryBot.create(:lead_provider_mentorship_status, mentorship_period:) }

  around { |example| freeze_time { example.run } }

  it "persists a changed status and reason and advances updated_at" do
    mentorship_period.update!(finished_on: Date.current)

    expect { job.perform }.to change { mentorship_status.reload.slice(:status, :reason, :updated_at) }
      .to({ status: "no-access-required", reason: "mentorship-expired", updated_at: Time.current })
  end

  it "preserves the status, reason and updated_at when nothing has changed" do
    expect { job.perform }.not_to(change { mentorship_status.reload.slice(:status, :reason, :updated_at) })
  end
end
