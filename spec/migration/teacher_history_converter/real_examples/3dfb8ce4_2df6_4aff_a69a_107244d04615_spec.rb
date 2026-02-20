describe "Real data check for user 3dfb8ce4-2df6-4aff-a69a-107244d04615", skip: "bad shape without a partnership" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "3dfb8ce4-2df6-4aff-a69a-107244d04615",
      created_at: Time.zone.local(2021, 11, 29, 12, 15, 55),
      updated_at: Time.zone.local(2025, 6, 6, 10, 6, 3),
      ect: {
        participant_profile_id: "68911843-25e7-4952-b585-f1eb4694d232",
        created_at: Time.zone.local(2021, 11, 29, 12, 15, 55),
        updated_at: Time.zone.local(2025, 6, 6, 10, 6, 3),
        induction_start_date: Date.new(2021, 11, 29),
        induction_completion_date: :ignore,
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: 2021,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 11, 29, 12, 15, 55),
            cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
          },
          {
            state: "deferred",
            reason: "other",
            created_at: Time.zone.local(2025, 6, 6, 10, 5, 40),
            cpd_lead_provider_id: "af89cf02-bbe0-423b-b2f6-bb2dbb97d141"
          }
        ],
        induction_records: [
          {
            start_date: Date.new(2021, 12, 1),
            end_date: Date.new(2025, 6, 6),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "466a5a58-98ec-42d1-aca5-54fb6f6c5169",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "a48b0804-deca-44d6-8a65-13462c8efdc9",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "84d07efd-ef9b-49c4-b25c-85b8b57cf8d0",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2021
            }
          },
          {
            start_date: Date.new(2025, 2, 19),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "active",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "466a5a58-98ec-42d1-aca5-54fb6f6c5169",
            training_provider_info: {},
            schedule_info: {
              schedule_id: "4cc26452-e018-4671-aac2-1d3f572a6aa1",
              identifier: "ecf-extended-september",
              name: "ECF Extended September",
              cohort_year: 2024
            }
          },
          {
            start_date: Date.new(2025, 6, 6),
            end_date: Date.new(2025, 2, 19),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "deferred",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "466a5a58-98ec-42d1-aca5-54fb6f6c5169",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "9f0a1bdd-b9af-4603-abfd-c1af01aded76",
                name: "Education Development Trust"
              },
              delivery_partner: {
                ecf1_id: "a48b0804-deca-44d6-8a65-13462c8efdc9",
                name: "Delivery partner 1"
              },
              cohort_year: 2021
            },
            schedule_info: {
              schedule_id: "84d07efd-ef9b-49c4-b25c-85b8b57cf8d0",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: 2021
            }
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
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 12, 1),
              finished_on: Date.new(2025, 6, 6),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 12, 1),
                  finished_on: Date.new(2025, 6, 6)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 2, 19),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 2, 19),
                  finished_on: nil
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 6, 6),
              finished_on: Date.new(2025, 2, 19),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 6, 6),
                  finished_on: Date.new(2025, 2, 19)
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
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2021, 12, 1),
              finished_on: Date.new(2025, 6, 6),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2021, 12, 1),
                  finished_on: Date.new(2025, 6, 6)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 2, 19),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 2, 19),
                  finished_on: nil
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 6, 6),
              finished_on: Date.new(2025, 2, 19),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 6, 6),
                  finished_on: Date.new(2025, 2, 19)
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
end
