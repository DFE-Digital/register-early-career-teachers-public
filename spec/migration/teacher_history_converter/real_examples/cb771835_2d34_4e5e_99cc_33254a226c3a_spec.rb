describe "Real data check for user cb771835-2d34-4e5e-99cc-33254a226c3a" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:input) do
    {
      trn: "1111111",
      full_name: "A Teacher",
      user_id: "cb771835-2d34-4e5e-99cc-33254a226c3a",
      created_at: Time.zone.local(2021, 9, 16, 16, 9, 11),
      updated_at: Time.zone.local(2025, 9, 23, 14, 9, 36),
      mentor: {
        participant_profile_id: "e2d85cb5-c31b-47de-b8b4-46bf1c5ddd18",
        created_at: Time.zone.local(2024, 9, 18, 14, 2, 24),
        updated_at: Time.zone.local(2025, 7, 24, 8, 26, 47),
        mentor_completion_date: :ignore,
        mentor_completion_reason: :ignore,
        payments_frozen_cohort_start_year: :ignore,
        induction_records: [
          {
            start_date: Date.new(2024, 6, 1),
            end_date: Date.new(2025, 9, 1),
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100003",
              name: "School 3"
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
                ecf1_id: "a529cfbb-5bcf-4dd5-b488-4525c49dbfae",
                name: "Delivery partner 2"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          },
          {
            start_date: Date.new(2025, 9, 1),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              urn: "100004",
              name: "School 4"
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
                ecf1_id: "a529cfbb-5bcf-4dd5-b488-4525c49dbfae",
                name: "Delivery partner 2"
              },
              cohort_year: 2024
            },
            schedule_info: {
              schedule_id: "a033708c-7aa4-4410-afbf-0e0f3f2f7466",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: 2024
            }
          }
        ],
        states: [
          {
            state: "active",
            reason: :ignore,
            created_at: Time.zone.local(2024, 9, 18, 14, 2, 25)
          }
        ],
        school_mentors: [
          {
            school: {
              urn: "100005",
              name: "School 5"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 21, 3)
          },
          {
            school: {
              urn: "100006",
              name: "School 6"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 21, 21)
          },
          {
            school: {
              urn: "100004",
              name: "School 4"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 21, 36)
          },
          {
            school: {
              urn: "100001",
              name: "School 1"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 21, 50)
          },
          {
            school: {
              urn: "100002",
              name: "School 2"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 22, 8)
          },
          {
            school: {
              urn: "100007",
              name: "School 7"
            },
            preferred_identity_email: "a.teacher@example.com",
            created_at: Time.zone.local(2024, 11, 21, 16, 22, 23)
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
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 6, 1),
              finished_on: Date.new(2025, 8, 31),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 1),
                  finished_on: Date.new(2025, 8, 31)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 9, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100005",
                name: "School 5"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100006",
                name: "School 6"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100001",
                name: "School 1"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100002",
                name: "School 2"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100007",
                name: "School 7"
              },
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

  context "when using the premium migrator" do
    let(:migration_mode) { :all_induction_records }

    let(:expected_output) do
      {
        teacher: hash_including(
          trn: "1111111",
          mentor_at_school_periods: array_including(
            hash_including(
              started_on: Date.new(2024, 6, 1),
              finished_on: Date.new(2025, 8, 31),
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2024, 6, 1),
                  finished_on: Date.new(2025, 8, 31)
                )
              )
            ),
            hash_including(
              started_on: Date.new(2025, 9, 1),
              finished_on: nil,
              training_periods: array_including(
                hash_including(
                  started_on: Date.new(2025, 9, 1),
                  finished_on: nil
                )
              )
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100005",
                name: "School 5"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100006",
                name: "School 6"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100001",
                name: "School 1"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100002",
                name: "School 2"
              },
              training_periods: []
            ),
            hash_including(
              started_on: Date.new(2024, 11, 21),
              finished_on: nil,
              school: {
                urn: "100007",
                name: "School 7"
              },
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
