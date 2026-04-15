describe "Real data check for user d7df730b-be0d-4f80-9c9d-5b2e2b24de98 (ignore_training patched in CSV)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "d7df730b-be0d-4f80-9c9d-5b2e2b24de98",
      created_at: Time.zone.local(2021, 9, 17, 15, 19, 54),
      updated_at: Time.zone.local(2025, 11, 27, 9, 19, 3),
      mentor: {
        participant_profile_id: "d620fb7c-722b-49e7-b254-2f479aeb1a56",
        created_at: Time.zone.local(2021, 9, 17, 15, 19, 54),
        updated_at: Time.zone.local(2025, 11, 27, 9, 19, 3),
        mentor_completion_date: Date.new(2021, 4, 19),
        mentor_completion_reason: "completed_during_early_roll_out",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 9, 4),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "81849d4a-d625-42b9-a4b0-b23290525c5c",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "b8a2dc4f-4e7f-4018-ad36-0cda869f9dd1",
              identifier: "ecf-replacement-september",
              name: "ECF Replacement September",
              cohort_year: 2021
            }
          },
          {
            induction_record_id: "602ff46c-7a77-48aa-b30e-6a9137a0f20d",
            start_date: Date.new(2023, 9, 4),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100002",
              name: "School 2"
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
                ecf1_id: "81849d4a-d625-42b9-a4b0-b23290525c5c",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "b8a2dc4f-4e7f-4018-ad36-0cda869f9dd1",
              identifier: "ecf-replacement-september",
              name: "ECF Replacement September",
              cohort_year: 2021
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 9, 17, 15, 19, 54),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 10, 18, 3, 5),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100002",
              name: "School 2"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2023, 9, 10, 18, 3, 5)
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2023, 9, 3),
              school: hash_including(
                urn: "100001",
                name: "School 1"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 9, 3),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "81849d4a-d625-42b9-a4b0-b23290525c5c", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 9, 4),
              finished_on: nil,
              school: hash_including(
                urn: "100002",
                name: "School 2"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2023, 9, 4),
                  finished_on: Date.new(2023, 9, 5),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "81849d4a-d625-42b9-a4b0-b23290525c5c", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            )
          )
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
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2023, 9, 3),
              school: hash_including(
                urn: "100001",
                name: "School 1"
              ),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 9, 3),
                  training_programme: "provider_led",
                  lead_provider_info: { ecf1_id: "99317668-2942-4292-a895-fdb075af067b", name: "Teach First" },
                  delivery_partner_info: { ecf1_id: "81849d4a-d625-42b9-a4b0-b23290525c5c", name: "Delivery partner 1" },
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 9, 4),
              finished_on: nil,
              school: hash_including(
                urn: "100002",
                name: "School 2"
              ),
              training_periods: []
            )
          )
        )
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
