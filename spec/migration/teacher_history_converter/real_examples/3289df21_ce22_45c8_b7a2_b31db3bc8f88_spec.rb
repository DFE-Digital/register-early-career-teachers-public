describe "Real data check for user 3289df21-ce22-45c8-b7a2-b31db3bc8f88 (ERO mentor not on 'keep' training period list" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "3289df21-ce22-45c8-b7a2-b31db3bc8f88",
      created_at: Time.zone.local(2022, 11, 30, 16, 28, 41),
      updated_at: Time.zone.local(2025, 7, 15, 15, 44, 0),
      mentor: {
        participant_profile_id: "0029f6c3-86cf-468d-837f-0cf1f0b5a1e3",
        created_at: Time.zone.local(2022, 11, 30, 16, 28, 41),
        updated_at: Time.zone.local(2025, 7, 15, 15, 44, 0),
        mentor_completion_date: Date.new(2021, 4, 19),
        mentor_completion_reason: "completed_during_early_roll_out",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "4c3f083b-a73e-4a55-8d0f-a35fb397df31",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "80e0a108-d5f7-433f-8c56-27b436b4dea8",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2021
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 11, 30, 16, 28, 41)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 11, 30, 16, 28, 41)
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2022, 11, 30, 16, 28, 41)
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: [
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              training_periods: []
            )
          ],
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: [
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: nil,
              school: hash_including(urn: "100001", name: "School 1"),
              # NOTE: ERO mentor with training combo not in the 'keep' list so no training period added
              training_periods: []
            )
          ],
          mentor_became_ineligible_for_funding_on: Date.new(2021, 4, 19),
          mentor_became_ineligible_for_funding_reason: "completed_during_early_roll_out"
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
