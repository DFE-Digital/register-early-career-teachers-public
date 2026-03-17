describe "Real data check for user f38e67d0-d01b-41ff-a197-ef58b4080a47" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "f38e67d0-d01b-41ff-a197-ef58b4080a47",
      created_at: Time.zone.local(2022, 7, 22, 17, 34, 50),
      updated_at: Time.zone.local(2026, 1, 16, 10, 2, 27),
      mentor: {
        participant_profile_id: "9278cc1a-29ee-4714-8ffa-4b1641a2c4df",
        created_at: Time.zone.local(2022, 7, 22, 17, 34, 50),
        updated_at: Time.zone.local(2026, 1, 16, 10, 2, 27),
        mentor_completion_date: Date.new(2023, 2, 23),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 2, 23),
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
                ecf1_id: "e0a93c21-86d4-4baa-badc-ced93609a625",
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
          },
          {
            start_date: Date.new(2024, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "0c6b3c61-53ab-4d62-bf94-44fe75b06a6d",
                name: "Delivery partner 2"
              },
              cohort_year: 2024
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
            created_at: Time.zone.local(2022, 7, 22, 17, 34, 50)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 22, 17, 34, 50)
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
          mentor_became_ineligible_for_funding_on: Date.new(2023, 2, 23),
          mentor_became_ineligible_for_funding_reason: "completed_declaration_received",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2023, 2, 23),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 2, 23),
                  lead_provider_info: hash_including(name: "Teach First"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2021
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 9, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 9, 1),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Education Development Trust"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2024
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

  context "when using the premium migrator", skip: "Implement the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(trn: "1111111")
      }
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
