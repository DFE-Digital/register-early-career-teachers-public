describe "Real data check for user d2526570-33b0-43c5-87a8-3e4f3060ea53" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "d2526570-33b0-43c5-87a8-3e4f3060ea53",
      created_at: Time.zone.local(2022, 7, 4, 12, 19, 36),
      updated_at: Time.zone.local(2025, 6, 30, 9, 9, 6),
      ect: {
        participant_profile_id: "02721c58-7991-46d5-865a-a541e00be865",
        created_at: Time.zone.local(2022, 7, 4, 12, 19, 36),
        updated_at: Time.zone.local(2025, 6, 30, 9, 9, 6),
        induction_start_date: Date.new(2022, 9, 1),
        induction_completion_date: Date.new(2024, 7, 19),
        pupil_premium_uplift: false,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: :ignore,
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2022, 7, 4, 12, 19, 36),
            cpd_lead_provider_id: :ignore
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 10, 5, 16, 11, 14),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2023, 10, 16, 16, 12, 4),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2023, 11, 14, 11, 34, 5),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "withdrawn",
            reason: "other",
            created_at: Time.zone.local(2024, 1, 24, 12, 48, 1),
            cpd_lead_provider_id: "bd152c5a-5ef4-4584-9c63-c32877dbba07"
          },
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 2, 26, 12, 18, 9),
            cpd_lead_provider_id: "fb9c56b2-252b-41fe-b6b2-ebf208999df9"
          }
        ],
        induction_records: [
          {
            induction_record_id: "5fc15502-ac51-4107-acbe-75f80eb204a2",
            start_date: Date.new(2022, 9, 1),
            end_date: Date.new(2023, 8, 31),
            created_at: Time.zone.local(2022, 7, 4, 12, 19, 36),
            updated_at: Time.zone.local(2023, 9, 12, 10, 50, 47),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100001",
              name: "School 1"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "7d7f29de-cbac-454e-bbfe-6b7dd411480c",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "87c8f24d-884d-4e0e-8357-9a2e0dd2986f",
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
            induction_record_id: "cfac5099-fd8c-45c4-894f-f6a0bbd1df92",
            start_date: Date.new(2023, 9, 1),
            end_date: Date.new(2023, 10, 16),
            created_at: Time.zone.local(2023, 10, 5, 16, 11, 14),
            updated_at: Time.zone.local(2023, 10, 16, 16, 12, 4),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f7cae7ba-9970-4841-a9e7-74b028c55c8e",
            appropriate_body: {
              ecf1_id: "ca09858e-15e5-443b-9e1e-ea34f74f4977",
              name: "North Northamptonshire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "87c8f24d-884d-4e0e-8357-9a2e0dd2986f",
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
            induction_record_id: "f2d2d39f-2e5f-41c6-978e-3a176180171b",
            start_date: Date.new(2023, 10, 16),
            end_date: Date.new(2023, 11, 14),
            created_at: Time.zone.local(2023, 10, 16, 16, 12, 4),
            updated_at: Time.zone.local(2023, 11, 14, 11, 34, 5),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f7cae7ba-9970-4841-a9e7-74b028c55c8e",
            appropriate_body: {
              ecf1_id: "ca09858e-15e5-443b-9e1e-ea34f74f4977",
              name: "North Northamptonshire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "87c8f24d-884d-4e0e-8357-9a2e0dd2986f",
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
            induction_record_id: "ac59ae6e-ea41-4470-a80d-25e4ae9305c4",
            start_date: Date.new(2023, 11, 14),
            end_date: Date.new(2024, 1, 24),
            created_at: Time.zone.local(2023, 11, 14, 11, 34, 5),
            updated_at: Time.zone.local(2024, 1, 24, 12, 48, 1),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f7cae7ba-9970-4841-a9e7-74b028c55c8e",
            appropriate_body: {
              ecf1_id: "ca09858e-15e5-443b-9e1e-ea34f74f4977",
              name: "North Northamptonshire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "87c8f24d-884d-4e0e-8357-9a2e0dd2986f",
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
            induction_record_id: "059f9a02-9dfd-44cb-a430-31c8649cce50",
            start_date: Date.new(2023, 11, 14),
            end_date: Date.new(2024, 2, 29), # leap year
            created_at: Time.zone.local(2023, 11, 14, 11, 38, 25),
            updated_at: Time.zone.local(2024, 2, 26, 12, 18, 9),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "leaving",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f7cae7ba-9970-4841-a9e7-74b028c55c8e",
            appropriate_body: {
              ecf1_id: "ca09858e-15e5-443b-9e1e-ea34f74f4977",
              name: "North Northamptonshire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "da470c27-05a6-4f5b-b9a9-58b04bfcc408",
                name: "Best Practice Network"
              },
              delivery_partner: {
                ecf1_id: "5865f6a2-c8e0-46bb-a025-b9f2341b18f3",
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
          },
          {
            induction_record_id: "7b277551-1882-4284-94c8-0a6090676cbb",
            start_date: Date.new(2024, 1, 24),
            end_date: Date.new(2023, 11, 14),
            created_at: Time.zone.local(2024, 1, 24, 12, 48, 1),
            updated_at: Time.zone.local(2024, 1, 24, 12, 48, 1),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100002",
              name: "School 2"
            },
            induction_status: "changed",
            training_status: "withdrawn",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f7cae7ba-9970-4841-a9e7-74b028c55c8e",
            appropriate_body: {
              ecf1_id: "ca09858e-15e5-443b-9e1e-ea34f74f4977",
              name: "North Northamptonshire"
            },
            training_provider_info: {
              lead_provider: {
                ecf1_id: "99317668-2942-4292-a895-fdb075af067b",
                name: "Teach First"
              },
              delivery_partner: {
                ecf1_id: "87c8f24d-884d-4e0e-8357-9a2e0dd2986f",
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
            induction_record_id: "d74b7293-c9d0-4aff-9ca4-a89ea0a92500",
            start_date: Date.new(2024, 2, 29),
            end_date: Date.new(2024, 7, 23),
            created_at: Time.zone.local(2024, 2, 26, 12, 18, 9),
            updated_at: Time.zone.local(2024, 7, 23, 4, 2, 18),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100003",
              name: "School 3"
            },
            induction_status: "changed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: "f9eeed7b-df76-4763-853e-71b9eccbdd68",
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "98396a47-50f0-49b8-8e13-1643a60b9de0",
                name: "Delivery partner 3"
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
            induction_record_id: "f1e411fc-b152-4bbb-977b-357808e6ebe0",
            start_date: Date.new(2024, 7, 23),
            end_date: :ignore,
            created_at: Time.zone.local(2024, 7, 23, 4, 2, 19),
            updated_at: Time.zone.local(2024, 7, 23, 4, 2, 19),
            training_programme: "full_induction_programme",
            cohort_year: 2022,
            school: {
              urn: "100003",
              name: "School 3"
            },
            induction_status: "completed",
            training_status: "active",
            preferred_identity_email: "a.teacher@example.com",
            mentor_profile_id: :ignore,
            appropriate_body: {},
            training_provider_info: {
              lead_provider: {
                ecf1_id: "3d7d8c90-a5a3-4838-84b2-563092bf87ee",
                name: "UCL Institute of Education"
              },
              delivery_partner: {
                ecf1_id: "98396a47-50f0-49b8-8e13-1643a60b9de0",
                name: "Delivery partner 3"
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
        ],
        mentor_at_school_periods: []
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode:).convert_to_ecf2! }

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          ect_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2022, 9, 1),
              finished_on: Date.new(2023, 8, 31),
              school: hash_including(name: "School 1"),
              training_periods: array_including(
                hash_including(
                  lead_provider_info: hash_including(name: "Teach First"),
                  started_on: Date.new(2022, 9, 1),
                  finished_on: Date.new(2023, 8, 31)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2023, 9, 1),
              finished_on: Date.new(2024, 2, 28),
              school: hash_including(name: "School 2"),
              training_periods: array_including(
                hash_including(
                  lead_provider_info: hash_including(name: "Teach First"),
                  started_on: Date.new(2023, 9, 1),
                  finished_on: Date.new(2023, 10, 16),
                  withdrawn_at: Time.zone.local(2023, 10, 16, 16, 12, 4),
                  withdrawal_reason: "other"
                ),
                hash_including(
                  lead_provider_info: hash_including(name: "Teach First"),
                  started_on: Date.new(2023, 11, 14),
                  finished_on: Date.new(2023, 11, 13),
                ),
                hash_including(
                  lead_provider_info: hash_including(name: "Best Practice Network"),
                  started_on: Date.new(2023, 11, 14),
                  finished_on: Date.new(2024, 2, 28),
                )
              )
            ),
            hash_including(
              school: hash_including(name: "School 3"),
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
