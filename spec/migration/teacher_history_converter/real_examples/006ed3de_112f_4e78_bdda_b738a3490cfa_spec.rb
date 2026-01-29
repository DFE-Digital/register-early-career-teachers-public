describe "Real data check for user 006ed3de-112f-4e78-bdda-b738a3490cfa" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "006ed3de-112f-4e78-bdda-b738a3490cfa",
      created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
      updated_at: Time.zone.local(2025, 1, 31, 6, 15, 25),
      ect: {
        participant_profile_id: "ef41f4ff-d8c6-4800-a32c-32b429bb694d",
        created_at: Time.zone.local(2022, 8, 11, 11, 29, 20),
        updated_at: Time.zone.local(2025, 1, 31, 6, 15, 25),
        induction_start_date: Date.new(2022, 9, 1),
        induction_completion_date: Date.new(2024, 7, 22),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 8, 11, 11, 29, 20)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 8, 11, 11, 29, 20)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 9, 4, 20, 3, 42)
          }
        ],
        induction_records: [
          {
            start_date: Time.zone.local(2022, 9, 1, 1, 0, 0),
            end_date: Time.zone.local(2023, 9, 1, 1, 0, 0),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "410e7dfe-7561-4149-aad5-5bfdd099d04c",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "47123e23-0c9f-49dc-ae4a-e2527b9fe4f8",
                name: "Delivery partner 1"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2022
            }
          },
          {
            start_date: Time.zone.local(2024, 8, 20, 3, 50, 29),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2022,
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
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "aeed99d7-0d79-49ee-840d-34d52910364b",
                name: "Delivery partner 2"
              },
              cohort_year: 2022
            },
            schedule_info: {
              schedule_id: "c4d6a996-b0fe-495e-be2e-11cb064253c2",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2022
            }
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
          ect_at_school_periods: array_including(
            hash_including(
              school: { urn: "100001", name: "School 1" },
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 9, 1),
              mentorship_periods: [],
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 9, 1),
                  lead_provider_info: hash_including(name: "Education Development Trust"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  contract_period_year: 2022
                )
              )
            ),
            hash_including(
              school: { urn: "100002", name: "School 2" },
              started_on: Date.new(2024, 8, 20),
              finished_on: nil,
              mentorship_periods: [],
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 8, 20),
                  finished_on: nil,
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  contract_period_year: 2022
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
      {}
    end

    it "matches the expected output" do
      expect(actual_output).to include(expected_output)
    end
  end
end
