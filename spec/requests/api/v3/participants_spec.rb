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

  let!(:school_partnership2) do
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership2)
  end
  let!(:lead_provider_delivery_partnership2) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lead_provider2)
  end
  let!(:active_lead_provider2) do
    FactoryBot.create(:active_lead_provider, lead_provider: lead_provider2)
  end
  let!(:lead_provider2) { FactoryBot.create(:lead_provider) }

  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: ect_teacher) }
  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher) }
  let!(:mentor_at_school_period2) { FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, started_on: mentor_at_school_period.finished_on.next_day) }
  let!(:both_ect_period) { FactoryBot.create(:ect_at_school_period, teacher: both_teacher) }
  let!(:both_mentor_period) { FactoryBot.create(:mentor_at_school_period, teacher: both_teacher) }

  before do
    # ECT only
    finished_on = ect_at_school_period.started_on + 30.days
    # latest
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: finished_on.next_day,
                      finished_on: ect_at_school_period.finished_on)
    # old
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: ect_at_school_period.started_on,
                      finished_on:)

    # Mentor only
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period:,
                      school_partnership:,
                      started_on: mentor_at_school_period.started_on,
                      finished_on: mentor_at_school_period.finished_on)
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period: mentor_at_school_period2,
                      school_partnership: school_partnership2,
                      started_on: mentor_at_school_period2.started_on,
                      finished_on: mentor_at_school_period2.finished_on)

    # Both ECT and mentor
    finished_on = both_ect_period.started_on + 15.days
    # old
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period: both_ect_period,
                      school_partnership:,
                      started_on: both_ect_period.started_on,
                      finished_on:)
    # latest
    FactoryBot.create(:training_period, :for_ect, :with_school_partnership,
                      ect_at_school_period: both_ect_period,
                      school_partnership:,
                      started_on: finished_on.next_day,
                      finished_on: both_ect_period.finished_on)

    finished_on = both_mentor_period.started_on + 10.days
    # old
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period: both_mentor_period,
                      school_partnership:,
                      started_on: both_mentor_period.started_on,
                      finished_on:)
    # latest
    FactoryBot.create(:training_period, :for_mentor, :with_school_partnership,
                      mentor_at_school_period: both_mentor_period,
                      school_partnership:,
                      started_on: finished_on.next_day,
                      finished_on: both_mentor_period.finished_on)
  end

  describe "#index" do
    let(:parsed_response) { JSON.parse(response.body)["data"] }

    it "returns the correct body" do
      authenticated_api_get(api_v3_participants_path)

      expect(response).to have_http_status(:ok)
      # debugger

      attrs1 = parsed_response.dig(0, "attributes")
      expect(attrs1).to include(
        "ecf_enrolments" => contain_exactly(
          include(
            "training_record_id" => ect_teacher.api_ect_training_record_id,
            "email" => ect_at_school_period.email,
            "lead_provider" => lead_provider.name,
            "created_at" => ect_at_school_period.created_at&.rfc3339
          )
        )
      )

      attrs2 = parsed_response.dig(1, "attributes")
      expect(attrs2).to include(
        "ecf_enrolments" => contain_exactly(
          include(
            "training_record_id" => mentor_teacher.api_mentor_training_record_id,
            "email" => mentor_at_school_period.email,
            "lead_provider" => lead_provider.name,
            "created_at" => mentor_at_school_period.created_at&.rfc3339
          )
        )
      )

      attrs3 = parsed_response.dig(2, "attributes")
      expect(attrs3).to include(
        "ecf_enrolments" => contain_exactly(
          include(
            "training_record_id" => both_teacher.api_ect_training_record_id,
            "email" => both_ect_period.email,
            "lead_provider" => lead_provider.name,
            "created_at" => both_ect_period.created_at&.rfc3339
          ),
          include(
            "training_record_id" => both_teacher.api_mentor_training_record_id,
            "email" => both_mentor_period.email,
            "lead_provider" => lead_provider.name,
            "created_at" => both_mentor_period.created_at&.rfc3339
          )
        )
      )
    end
  end
end
