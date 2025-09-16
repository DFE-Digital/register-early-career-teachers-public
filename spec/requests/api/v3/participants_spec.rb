RSpec.describe "Participants API", type: :request do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:ect_teacher) { FactoryBot.create(:teacher) }
  let!(:mentor_teacher) { FactoryBot.create(:teacher) }
  let!(:both_teacher) { FactoryBot.create(:teacher) }

  let!(:school_partnership) do
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
  end
  let!(:lead_provider_delivery_partnership) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
  end
  let!(:active_lead_provider) do
    FactoryBot.create(:active_lead_provider, lead_provider:)
  end

  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: ect_teacher) }
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher) }
  let!(:both_ect_period) { FactoryBot.create(:ect_at_school_period, teacher: both_teacher) }
  let!(:both_mentor_period) { FactoryBot.create(:mentor_at_school_period, teacher: both_teacher) }

  before do
    # ECT only
    finished_on = ect_at_school_period.started_on + 30.days
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: ect_at_school_period.started_on,
                      finished_on:)
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: finished_on.next_day,
                      finished_on: ect_at_school_period.finished_on)

    # Mentor only
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period:,
                      school_partnership:,
                      started_on: mentor_at_school_period.started_on,
                      finished_on: mentor_at_school_period.finished_on)

    # Both ECT and mentor
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period: both_ect_period,
                      school_partnership:,
                      started_on: both_ect_period.started_on,
                      finished_on: both_ect_period.finished_on)
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period: both_mentor_period,
                      school_partnership:,
                      started_on: both_mentor_period.started_on,
                      finished_on: both_mentor_period.finished_on)
  end

  describe "#index" do
    let(:parsed_response) { JSON.parse(response.body)["data"] }

    it "returns the correct body" do
      authenticated_api_get(api_v3_participants_path)

      expect(response).to have_http_status(:ok)
      expect(parsed_response).to include(
        include(
          "type" => "participant",
          "attributes" => include(
            "ecf_enrolments" => contain_exactly(
              include("email" => ect_at_school_period.email, "training_record_id" => ect_teacher.api_ect_profile_id)
            )
          )
        ),
        include(
          "type" => "participant",
          "attributes" => include(
            "ecf_enrolments" => contain_exactly(
              include("email" => mentor_at_school_period.email, "training_record_id" => mentor_teacher.api_mentor_profile_id)
            )
          )
        ),
        include(
          "type" => "participant",
          "attributes" => include(
            "ecf_enrolments" => contain_exactly(
              include("email" => both_ect_period.email, "training_record_id" => both_teacher.api_ect_profile_id),
              include("email" => both_mentor_period.email, "training_record_id" => both_teacher.api_mentor_profile_id)
            )
          )
        )
      )
    end
  end
end
