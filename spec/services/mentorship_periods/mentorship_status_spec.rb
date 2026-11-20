RSpec.describe MentorshipPeriods::MentorshipStatus do
  subject(:service) { described_class.new(mentorship_period:) }

  let(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished) }
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school: mentee.school) }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, school: mentor.school, lead_provider:) }

  before { FactoryBot.create(:training_period, :for_ect, ect_at_school_period: mentee, school_partnership:) }

  it "creates a new status for each lead provider linked to the mentee's training periods" do
    # Other lead provider linked to only the mentor.
    FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: mentor)

    # Remove any statuses created during callbacks.
    mentorship_period.lead_provider_mentorship_statuses.destroy_all

    expect { service.refresh! }.to change(LeadProviderMentorshipStatus, :count).by(1)

    expect(mentorship_period.lead_provider_mentorship_statuses.pluck(:lead_provider_id)).to contain_exactly(lead_provider.id)
  end

  it "updates existing statuses for lead providers linked to the mentee's training periods" do
    mentorship_status = mentorship_period.lead_provider_mentorship_statuses.sole

    mentorship_period.update!(finished_on: Date.tomorrow)

    travel_to(2.days.from_now) do
      expect { service.refresh! }
        .to change { mentorship_status.reload.attributes.slice("status", "reason") }
        .from("status" => "access-and-support-only", "reason" => "no-known-training")
        .to("status" => "no-access-required", "reason" => "mentorship-expired")
    end

    expect(LeadProviderMentorshipStatus.count).to eq(1)
  end
end
