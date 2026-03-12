describe "Real data check for user 04dd6b10-0a82-4d89-a12f-543360dc8b15" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "04dd6b10-0a82-4d89-a12f-543360dc8b15",
      created_at: Time.zone.local(2021, 9, 16, 14, 14, 17),
      updated_at: Time.zone.local(2025, 6, 30, 10, 6, 45),
      ect: {
        participant_profile_id: "1b47db55-1898-4946-b5f5-0acc11e100bd",
        created_at: Time.zone.local(2021, 9, 16, 14, 14, 17),
        updated_at: Time.zone.local(2025, 6, 30, 10, 6, 45),
        induction_start_date: Date.new(2021, 9, 1),
        induction_completion_date: Date.new(2023, 7, 21),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2021, 9, 16, 14, 14, 17)
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 9, 12, 12, 19, 55)
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2023, 2, 28, 12, 41, 18)
          }
        ],
        induction_records: [
          {
            induction_record_id: "69ad02bc-ef8c-4f12-b206-67068b6ad5ee",
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2023, 2, 28),
            created_at: Time.zone.local(2022, 2, 9, 10, 53, 15),
            updated_at: Time.zone.local(2023, 2, 28, 12, 41, 18),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "af486b0f-2afa-43e6-a212-e2d76fd8c78f",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "ec43e381-a6c3-43c5-b534-8f8f72a861f1",
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
            induction_record_id: "c83ffdeb-0d26-45a7-83d1-a90234942df6",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2023, 9, 7),
            created_at: Time.zone.local(2022, 9, 12, 12, 19, 55),
            updated_at: Time.zone.local(2023, 9, 7, 6, 34, 48),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "66247b7b-8fdd-425c-8d8a-e17de9f65104",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "0c344e53-934d-4275-ba85-fe72c7cc5ce5",
                name: "Delivery partner 2"
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
            induction_record_id: "e790dfa5-664b-4c5d-abf0-eb4989e59acd",
            start_date: Date.new(2023, 2, 28),
            end_date: Date.new(2022, 7, 21),
            created_at: Time.zone.local(2023, 2, 28, 12, 41, 18),
            updated_at: Time.zone.local(2023, 2, 28, 12, 41, 18),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "af486b0f-2afa-43e6-a212-e2d76fd8c78f",
            training_provider_info: {
              lead_provider: {
                ecf1_id: "c3bc3cee-a636-42d6-8324-c033a6c38d31",
                name: "Ambition Institute"
              },
              delivery_partner: {
                ecf1_id: "ec43e381-a6c3-43c5-b534-8f8f72a861f1",
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
            induction_record_id: "78e1b0e6-7f57-4c0e-a61d-b34b6cab6814",
            start_date: Date.new(2023, 9, 7),
            end_date: Date.new(2023, 9, 25),
            created_at: Time.zone.local(2023, 9, 7, 6, 34, 48),
            updated_at: Time.zone.local(2024, 1, 9, 14, 46, 47),
            training_programme: "full_induction_programme",
            cohort_year: 2021,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "0c344e53-934d-4275-ba85-fe72c7cc5ce5",
                name: "Delivery partner 2"
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
            induction_record_id: "b6dcf4cd-8a7d-4eaf-a1f3-3364b9d26767",
            start_date: Date.new(2023, 9, 25),
            end_date: :ignore,
            created_at: Time.zone.local(2023, 9, 25, 9, 5, 13),
            updated_at: Time.zone.local(2023, 9, 25, 9, 5, 13),
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
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "0c344e53-934d-4275-ba85-fe72c7cc5ce5",
                name: "Delivery partner 2"
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
        mentor_at_school_periods: []
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  context "when using the economy migrator" do
    let(:migration_mode) { :latest_induction_records }

    let(:expected_output) { {} }

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
              started_on: Date.new(2021, 9, 1),
              finished_on: Date.new(2023, 2, 28),
              training_periods: array_including(
                hash_including(
                  lead_provider_info: hash_including(name: "Ambition Institute"),
                  delivery_partner_info: hash_including(name: "Delivery partner 1"),
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 2, 28),
                  contract_period_year: 2021,
                  withdrawn_at: Time.zone.local(2023, 2, 28, 12, 41, 18),
                  withdrawal_reason: "other"
                )
              )
            ),
            hash_including(
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 7, 21), # induction_completion_date
              training_periods: array_including(
                hash_including(
                  lead_provider_info: hash_including(name: "Teach First"),
                  delivery_partner_info: hash_including(name: "Delivery partner 2"),
                  started_on: Date.new(2021, 9, 1),
                  finished_on: Date.new(2023, 7, 21), # induction_completion_date
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
end
